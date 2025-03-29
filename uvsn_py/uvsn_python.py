import streamlit as st
import rawpy
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import tempfile
import os
import pandas as pd
from io import BytesIO
import base64

# Set page configuration
st.set_page_config(page_title="Chromaticity Analyzer", layout="wide")

def create_temp_file(content, extension=".jpg"):
    """Create a temporary file with the provided content."""
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=extension)
    temp_file.write(content)
    temp_file.close()
    return temp_file.name

def calculate_chromaticity(file_path, is_raw=True):
    """
    Reads an image (RAW or regular), extracts RGB values, and computes average chromaticity.
    """
    try:
        if is_raw:
            with rawpy.imread(file_path) as raw:
                rgb_image = raw.postprocess(output_bps=8, use_camera_wb=True)
        else:
            img = Image.open(file_path)
            rgb_image = np.array(img)

        # Normalize to range [0, 1]
        rgb_float = rgb_image.astype(np.float32) / 255.0 if rgb_image.dtype == np.uint8 else rgb_image.astype(np.float32) / 65535.0
        r, g, b = rgb_float[..., 0], rgb_float[..., 1], rgb_float[..., 2]

        # Compute chromaticity
        total = r + g + b
        mask = total > 1e-6  # Avoid division by zero

        r_chromaticity = np.zeros_like(r)
        g_chromaticity = np.zeros_like(g)

        r_chromaticity[mask] = r[mask] / total[mask]
        g_chromaticity[mask] = g[mask] / total[mask]

        # Calculate average r and g
        mean_r = np.mean(r_chromaticity[mask])
        mean_g = np.mean(g_chromaticity[mask])

        # Calculate statistics
        stats = {
            'mean_r': mean_r,
            'mean_g': mean_g,
            'std_r': np.std(r_chromaticity[mask]),
            'std_g': np.std(g_chromaticity[mask])
        }
        return mean_r, mean_g, rgb_image, stats

    except Exception as e:
        st.error(f"Error processing image: {str(e)}")
        return None, None, None, None

def plot_average_chromaticity(mean_r, mean_g):
    """
    Plots the average chromaticity as a single point.
    """
    fig, ax = plt.subplots(figsize=(8, 6))

    # Plot the average chromaticity point
    ax.scatter(mean_r, mean_g, s=100, color='red', marker='o', label='Average Chromaticity')

    # Set axis labels and limits
    ax.set_xlabel('Red Chromaticity (r)')
    ax.set_ylabel('Green Chromaticity (g)')
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.set_title('Average Chromaticity')
    ax.legend()
    ax.grid(True)

    return fig

def get_csv_download_link(stats):
    """Generates a link to download statistics as a CSV file."""
    df = pd.DataFrame([stats])
    csv = df.to_csv(index=False)
    b64 = base64.b64encode(csv.encode()).decode()
    href = f'<a href="data:file/csv;base64,{b64}" download="chromaticity_stats.csv">Download Statistics</a>'
    return href

def get_image_download_link(img):
    """Generates a link to download the processed image."""
    buffered = BytesIO()
    img.save(buffered, format="JPEG", quality=90)
    img_str = base64.b64encode(buffered.getvalue()).decode()
    href = f'<a href="data:file/jpg;base64,{img_str}" download="processed_image.jpg">Download Processed Image</a>'
    return href

def main():
    st.title("Chromaticity Analyzer")

    # Tabs for camera input and file upload
    tab1, tab2 = st.tabs(["📷 Take a Picture", "📁 Upload an Image"])

    processed_data = None

    with tab1:
        st.write("Capture an image using your device's camera.")
        picture = st.camera_input("Take a picture")

        if picture is not None:
            with st.spinner("Processing image..."):
                temp_file = create_temp_file(picture.getvalue(), ".jpg")
                processed_data = calculate_chromaticity(temp_file, is_raw=False)

                os.remove(temp_file)

    with tab2:
        st.write("Upload an image file.")
        uploaded_file = st.file_uploader("Choose an image", type=["jpg", "jpeg", "png", "dng"])

        if uploaded_file is not None:
            with st.spinner("Processing image..."):
                file_extension = os.path.splitext(uploaded_file.name)[1].lower()
                is_raw = file_extension in ['.dng']
                temp_file = create_temp_file(uploaded_file.getvalue(), file_extension)

                processed_data = calculate_chromaticity(temp_file, is_raw=is_raw)

                os.remove(temp_file)

    if processed_data and all(x is not None for x in processed_data):
        mean_r, mean_g, processed_image, stats = processed_data

        col1, col2 = st.columns([2, 3])

        with col1:
            st.subheader("Processed Image")
            pil_img = Image.fromarray(processed_image)
            st.image(pil_img)
            st.markdown(get_image_download_link(pil_img), unsafe_allow_html=True)

            st.subheader("Statistics")
            stats_df = pd.DataFrame({
                'Metric': ['Mean Red', 'Mean Green', 'Std Red', 'Std Green'],
                'Value': [
                    f"{stats['mean_r']:.4f}",
                    f"{stats['mean_g']:.4f}",
                    f"{stats['std_r']:.4f}",
                    f"{stats['std_g']:.4f}"
                ]
            })
            st.table(stats_df)
            st.markdown(get_csv_download_link(stats), unsafe_allow_html=True)

        with col2:
            st.subheader("Average Chromaticity Plot")
            fig = plot_average_chromaticity(mean_r, mean_g)
            st.pyplot(fig)
            st.subheader("Reference")
            st.image("https://clarkvision.com/articles/color-cie-chromaticity-and-perception/color-rgb-xy-cie1931-diagram1g1000spjfjl1-1000-ciesrgb-axes-waveticks-c1-srgb-800.jpg")


if __name__ == "__main__":
    main()
