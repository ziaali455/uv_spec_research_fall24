import streamlit as st
import rawpy
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ExifTags
import tempfile
import os
import pandas as pd
from io import BytesIO
import base64
import json
import math
import zipfile

st.set_page_config(page_title="Chromaticity Analyzer", layout="wide")

if "results_jsons" not in st.session_state:
    st.session_state.results_jsons = []

lamp_options = [
    "222 Ushio", "222 Nukit", "222 Lumen", "222 Unfiltered",
    "207 KrBr", "254", "265 LED", "280 LED", "295 LED", "302",
    "365", "sunlight", "Room light (fluorescent)"
]

def create_temp_file(content, extension=".jpg"):
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=extension)
    temp_file.write(content)
    temp_file.close()
    return temp_file.name

def calculate_chromaticity(file_path, is_raw=True):
    try:
        if is_raw:
            with rawpy.imread(file_path) as raw:
                # Black level correction
                raw_image = raw.raw_image_visible.astype(np.float32)
                black_level = np.mean(raw.black_level_per_channel)
                raw_image -= black_level
                raw_image = np.clip(raw_image, 0, None)

                # Demosaic to RGB
                rgb_image = raw.postprocess(
                    output_bps=16,
                    no_auto_bright=True,
                    use_camera_wb=False,
                    gamma=(1, 1),
                    output_color=rawpy.ColorSpace.raw
                )
        else:
            img = Image.open(file_path).convert("RGB")
            rgb_image = np.array(img).astype(np.float32)

        # Normalize to [0, 1] range
        rgb_float = rgb_image / np.max(rgb_image)
        r, g, b = rgb_float[..., 0], rgb_float[..., 1], rgb_float[..., 2]
        total = r + g + b
        #avoid dividing by 0 for nearly black pixels
        mask = total > 1e-6

        r_chromaticity = np.zeros_like(r)
        g_chromaticity = np.zeros_like(g)
        r_chromaticity[mask] = r[mask] / total[mask]
        g_chromaticity[mask] = g[mask] / total[mask]

        # Compute stats
        stats = {
            'mean_r': float(np.mean(r_chromaticity[mask])),
            'mean_g': float(np.mean(g_chromaticity[mask])),
            'std_r': float(np.std(r_chromaticity[mask])),
            'std_g': float(np.std(g_chromaticity[mask])),
            'max_r': float(np.max(r_chromaticity[mask])),
            'max_g': float(np.max(g_chromaticity[mask]))
        }

        return stats, rgb_image

    except Exception as e:
        st.error(f"Error processing image: {str(e)}")
        return None, None



def extract_exif_and_compute_brightness(img: Image.Image):
    try:
        exif = img._getexif()
    except:
        exif = None

    exif_data = {}
    if exif:
        for tag, value in exif.items():
            tag_name = ExifTags.TAGS.get(tag, tag)
            exif_data[tag_name] = value

    iso = exif_data.get('ISOSpeedRatings', None)
    f_number = exif_data.get('FNumber', None)
    exposure = exif_data.get('ExposureTime', None)

    sv = math.log2(iso / 3.3333) if iso else None
    av = 2 * math.log2(f_number) if f_number else None
    tv = -math.log2(exposure) if exposure else None
    bv = av + tv - sv if all(v is not None for v in [sv, av, tv]) else None

    return {
        "ISOSpeedRatings": iso,
        "FNumber": f_number,
        "ExposureTime": exposure,
        "S_v": sv,
        "A_v": av,
        "T_v": tv,
        "B_v": bv
    }

def plot_average_chromaticity(stats):
    fig, ax = plt.subplots(figsize=(8, 6))
    ax.scatter(stats['mean_r'], stats['mean_g'], s=100, color='red', marker='o', label='Average Chromaticity')
    ax.set_xlabel('Red Chromaticity (r)')
    ax.set_ylabel('Green Chromaticity (g)')
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_title('Average Chromaticity')
    ax.legend()
    ax.grid(True)
    return fig

def get_image_download_link(img):
    buffered = BytesIO()
    img.save(buffered, format="TIFF")
    img_str = base64.b64encode(buffered.getvalue()).decode()
    return f'<a href="data:image/tiff;base64,{img_str}" download="processed_image.tiff">Download Image</a>'

def main():
    st.title("Chromaticity Analyzer")

    tab1, tab2 = st.tabs(["📷 Take a Picture", "📁 Upload an Image"])
    processed_image = None
    stats = None
    uploaded_file = None

    with tab1:
        st.write("Capture an image using your device's camera.")
        picture = st.camera_input("Take a picture")
        if picture:
            with st.spinner("Processing image..."):
                temp_file = create_temp_file(picture.getvalue(), ".jpg")
                stats, processed_image = calculate_chromaticity(temp_file, is_raw=False)
                uploaded_file = picture
                os.remove(temp_file)

    with tab2:
        st.write("Upload an image file.")
        uploaded_file = st.file_uploader("Choose an image", type=["jpg", "jpeg", "png", "dng", "tiff"])
        if uploaded_file:
            with st.spinner("Processing image..."):
                ext = os.path.splitext(uploaded_file.name)[1].lower()
                is_raw = ext in ['.dng']
                temp_file = create_temp_file(uploaded_file.getvalue(), ext)
                stats, processed_image = calculate_chromaticity(temp_file, is_raw=is_raw)
                os.remove(temp_file)

    if stats and processed_image is not None:
        col1, col2 = st.columns([2, 3])

        with col1:
            st.subheader("Processed Image")
            display_image = (processed_image / 256).astype(np.uint8)
            pil_img = Image.fromarray(display_image)
            st.image(pil_img)
            st.markdown(get_image_download_link(pil_img), unsafe_allow_html=True)

            st.subheader("Chromaticity Stats")
            st.table(pd.DataFrame(stats.items(), columns=["Metric", "Value"]))

        with col2:
            st.subheader("Average Chromaticity Plot")
            fig = plot_average_chromaticity(stats)
            st.pyplot(fig)

        lamp_condition = st.selectbox("Select Lamp Condition", lamp_options)

        if st.button("Save Image Stats to JSON"):
            exif_stats = extract_exif_and_compute_brightness(pil_img)
            result = {
                "image_name": uploaded_file.name if uploaded_file else "camera_image",
                "lamp_condition": lamp_condition,
                "chromaticity": stats,
                "exif_and_brightness": {
                    k: float(v) if isinstance(v, (int, float, np.number)) and v is not None else v
                    for k, v in exif_stats.items()
                }
            }
            st.session_state.results_jsons.append((result["image_name"], json.dumps(result, indent=2)))
            st.success("Saved! Add more images or download all.")

    if st.session_state.results_jsons:
        if st.button("Download All as ZIP"):
            zip_buffer = BytesIO()
            with zipfile.ZipFile(zip_buffer, "w") as zipf:
                for name, data in st.session_state.results_jsons:
                    json_name = os.path.splitext(name)[0] + "_stats.json"
                    zipf.writestr(json_name, data)
            zip_buffer.seek(0)
            b64 = base64.b64encode(zip_buffer.read()).decode()
            href = f'<a href="data:application/zip;base64,{b64}" download="all_image_stats.zip">📦 Download All Image Stats</a>'
            st.markdown(href, unsafe_allow_html=True)

if __name__ == "__main__":
    main()
