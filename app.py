import streamlit as st
from PIL import Image
import os,io
from google.cloud import storage
import subprocess

storage_client = storage.Client()
bucket_name = "pwm-lowa"
bucket = storage_client.bucket(bucket_name)

st.title("Veo test")
if "disabled" not in st.session_state:
    st.session_state.disabled = False

def disable():
    st.session_state.disabled = True

def enable():
    st.session_state.disabled = False

def correct_image_orientation(image):
    if hasattr(image, '_getexif'):
        try:
            exif = image._getexif()
            if exif:
                orientation = exif.get(274)  # 274是方向标签的ID
                if orientation:
                    rotations = {
                        3: 180,
                        6: 270,
                        8: 90
                    }
                    if orientation in rotations:
                        return image.rotate(rotations[orientation], expand=True)
        except Exception as e:
            pass
    return image

uploaded_file = st.file_uploader(label="Prompt image (Optioanl)", type=['png', 'jpg', 'jpeg'])
if uploaded_file:
    image = Image.open(uploaded_file)
    # 校正图片方向
    corrected_image = correct_image_orientation(image)
    st.image(corrected_image, caption='image uploaded')

text_input = st.text_area(label="Prompt text", placeholder="your prompt here", height=200)
seed = st.number_input(label="Seed",
                       min_value=1,
                       max_value=1000000000,
                       value=50,
                       step=1,
                       format="%d")
aspect_ratio = st.selectbox(
    label="Aspect Ratio",
    options=["16:9", "9:16"],
    index=0,  # 默认选择第一个选项
)


def save_image(uploaded_file):
    filename = uploaded_file.name
    save_path = os.path.join('uploads', filename)
    with open(save_path, "wb") as f:
        f.write(uploaded_file.getvalue())


if st.button("Generate", disabled=st.session_state.disabled, on_click=disable):
    disable()
    try:
        if text_input and uploaded_file:
            print("start processing...")
            # 重新打开和处理图片
            image = Image.open(uploaded_file)
            corrected_image = correct_image_orientation(image)
            # 将校正后的图片转换为字节流
            img_byte_arr = io.BytesIO()
            corrected_image.save(img_byte_arr, format=image.format)
            img_byte_arr.seek(0)
            
            filename = uploaded_file.name
            mimeType = uploaded_file.type
            blob = bucket.blob("veotest/" + filename)
            blob.upload_from_file(img_byte_arr)
            input_url = f"gs://{bucket_name}/veotest/{filename}"
            result = subprocess.run(["bash", "veo.sh",  text_input, str(seed), aspect_ratio, input_url, mimeType], capture_output=True, text=True)
            if 'http' in result.stdout:
                st.markdown("[video link]("+result.stdout+")")
            else:
                st.write(result.stdout)
            print(result.stdout)
        elif text_input:
            result = subprocess.run(["bash", "veo.sh", text_input, str(seed), aspect_ratio], capture_output=True, text=True)
            if 'http' in result.stdout:
                st.markdown("[video link]("+result.stdout+")")
            else:
                st.write(result.stdout)
            print(result.stdout)
        else:
            st.error("prompt text can not be empty!")
    except Exception as e:
        st.error(f"Error: {str(e)}")
    finally:
        enable()