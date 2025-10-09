# SerDes LoggingSystem

## 项目说明 / Project Description

此项目为鄙人的本科毕业设计。项目使用 **FPGA、DSP、BOSA (Bi-Directional Optical Sub-Assembly)** 组件，  
实现了一套能够达到 **上行 10 Mbps（井下到地面回传数据）**、**下行 500 Kbps（地面到井下下发指令）** 的 **全双工通信系统**。

This project was my **undergraduate thesis**, which implemented a **full-duplex communication system** using **FPGA, DSP, and BOSA (Bi-Directional Optical Sub-Assembly)** modules.  
It achieved an **uplink data rate of 10 Mbps (from downhole to surface)** and a **downlink rate of 500 Kbps (from surface to downhole)**.

---

## 文件结构 / Project Structure

本项目包含通信系统中 **FPGA 部分的 Verilog 代码**，不包含 DSP 部分代码。  
内容分为两个主要文件夹：

This repository contains **only the FPGA-side Verilog source code** (the DSP portion is not included).  
The project is divided into two main directories:

SerDes_LoggingSystem/
├── DownholeBusControlBoard/ # 井下部分 / Downhole module
└── Surface/ # 地面部分 / Surface module
