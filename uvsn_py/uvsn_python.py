

import streamlit as st
import rawpy
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import io

def calculate_chromaticity(dng_path):
    """
    Reads a DNG RAW image, extracts RGB values, and computes chromaticity.
    """
    with rawpy.imread(dng_path) as raw:
        # Convert RAW image to RGB
        rgb_image = raw.postprocess(output_bps=16)
        
        # Normalize to range [0, 1]
        rgb_float = rgb_image.astype(np.float32)
        r, g, b = rgb_float[..., 0], rgb_float[..., 1], rgb_float[..., 2]
        total = r + g + b
        
        # Avoid division by zero
        total[total == 0] = 1e-6
        
        # Compute chromaticity
        r_chromaticity = r / total
        g_chromaticity = g / total
        b_chromaticity = b / total
        
        return r_chromaticity, g_chromaticity, b_chromaticity

def plot_chromaticity(r_chroma, g_chroma, b_chroma):
    """
    Plots the chromaticity distribution as a 2D histogram.
    """
    plt.figure(figsize=(8, 6))
    plt.hist2d(r_chroma.flatten(), g_chroma.flatten(), bins=100, cmap='viridis')
    plt.xlabel('Red Chromaticity')
    plt.ylabel('Green Chromaticity')
    plt.title('Chromaticity Distribution')
    plt.colorbar(label='Pixel Count')
    return plt

def main():
    st.title("Chromaticity Analysis from RAW Images")
    
    # Option to upload or take a picture
    option = st.radio("Choose an option:", ("Upload a RAW image", "Take a picture with your camera"))
    
    if option == "Upload a RAW image":
        uploaded_file = st.file_uploader("Upload a RAW image (DNG format)", type=["dng"])
        if uploaded_file is not None:
            # Save the uploaded file to a temporary file
            with open("temp.dng", "wb") as f:
                f.write(uploaded_file.getbuffer())
            
            # Calculate chromaticity
            r_chroma, g_chroma, b_chroma = calculate_chromaticity("temp.dng")
            
            # Plot chromaticity
            plt = plot_chromaticity(r_chroma, g_chroma, b_chroma)
            st.pyplot(plt)
    
    elif option == "Take a picture with your camera":
        st.write("Please ensure your camera is set to capture RAW images (DNG format).")
        picture = st.camera_input("Take a picture")
        
        if picture is not None:
            # Save the captured image to a temporary file
            with open("temp.dng", "wb") as f:
                f.write(picture.getbuffer())
            
            # Calculate chromaticity
            r_chroma, g_chroma, b_chroma = calculate_chromaticity("temp.dng")
            
            # Plot chromaticity
            plt = plot_chromaticity(r_chroma, g_chroma, b_chroma)
            st.pyplot(plt)

if __name__ == "__main__":
    main()