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

> Typical literature reports pre-activation ≈ 0.05–0.15 s before contact and post-activation ≈ 0.15–0.25 s after contact【1】【2】.

---

📊 Applications

- ACL reconstruction research  
- Landing mechanics and neuromuscular control  
- Injury prevention studies  
- Skill-based jump-landing assessments  

---

 📦 Requirements

- MATLAB R2021a or newer  
- Signal Processing Toolbox  
- Input file: Excel (`.xlsx`) with columns as specified  

---

 ⚙️ Usage

```matlab
% Place your Excel file (e.g., adinevand.land2.xlsx) in the same folder
run('Landing_EMG_Fz_Analysis.m')
🔗 References

【1】Santello, M. (2005). Feedforward control of hand posture and force during grip–load force coordination. J. Neurophysiol.

【2】Cowling, E. J., & Steele, J. R. (2001). The effect of gender and task on neuromuscular control during landing. J. Electromyogr. Kinesiol.

【3】McNair, P. J., & Marshall, R. N. (1994). Landing characteristics in subjects with normal and anterior cruciate ligament-deficient knees. Arch. Phys. Med. Rehabil.

👨‍💻 Author

Aria Behroozi
MSc Candidate – Sport Biomechanics
University of Tehran
📫 LinkedIn : www.linkedin.com/in/aria-behroozi-1996

If this code helps your research, please ⭐ star the repo and cite it in your work.


