# Landing Task EMG & Force Plate Analysis (MATLAB)

This repository provides a fully transparent and research-oriented MATLAB pipeline for analyzing **landing biomechanics** — combining **vertical ground reaction force (Fz)** and **surface EMG signals** to identify **muscle activation patterns** during landing.

---

🧠 Overview

Landing tasks are widely used in sports biomechanics to evaluate **neuromuscular control** and **injury risk** (especially for ACL-related research).  
This code automates the detection of:

- **Force plate events:** contact onset & offset (based on 10% body weight threshold)
- **EMG preprocessing:** baseline correction, band-pass filtering (20–400 Hz), rectification, and envelope creation
- **Onset and offset detection:** using mean + SD thresholds and a **stability rule** (≥ 25–50 ms)
- **Feedforward (pre-activation)** and **Feedback (post-activation)** timing relative to ground contact

All calculations follow protocols supported by published research on neuromuscular activation during landing【1】【2】【3】.

---

 🚀 Features

- 🔹 Automated **body weight detection** from stable standing phase  
- 🔹 **Butterworth filtering** for both force and EMG  
- 🔹 Baseline mean + 3SD thresholding for EMG onset  
- 🔹 Dual-threshold hysteresis (3SD for onset, 1.5SD for offset)  
- 🔹 **Feedforward (pre-activation)** vs **reactive activation** classification  
- 🔹 Visualizations for each phase: raw vs filtered, envelope, onset/offset events  

---

🧩 How It Works

1. **Input:** Excel file (`.xlsx`) with  
   - Column 2: EMG signal  
   - Column 11: Fz (vertical ground reaction force)  

2. **Output:**  
   - Detected **contact onset & offset** (force plate)  
   - **EMG onset & offset** with thresholds  
   - Printed report showing feedforward / feedback timings  
   - Figures illustrating all processing steps  

---

 🧪 Example Output
 Feedforward (Pre-activation): 0.706 s before contact
Post-activation: 0.221 s after contact ended

