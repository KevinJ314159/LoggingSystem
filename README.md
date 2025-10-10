# SerDes LoggingSystem

## 项目说明 / Project Description

此项目为鄙人的本科毕业设计。项目使用 **FPGA、DSP、BOSA (Bi-Directional Optical Sub-Assembly)** 组件，  
实现了一套能够达到 **上行 10 Mbps（井下到地面回传数据）**、**下行 500 Kbps（地面到井下下发指令）** 的 **全双工通信系统**。

This project was my **undergraduate thesis**, which implemented a **full-duplex communication system** using **FPGA, DSP, and BOSA (Bi-Directional Optical Sub-Assembly)** modules.  
It achieved an **uplink data rate of 10 Mbps (from downhole to surface)** and a **downlink rate of 500 Kbps (from surface to downhole)**.

[测井通信系统结构图 System Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%872.jpg)
---

## 文件结构 / Project Structure

本项目包含通信系统中 **FPGA 部分的 Verilog 代码**，不包含 DSP 部分代码。  
内容分为两个主要文件夹：

This repository contains **only the FPGA-side Verilog source code** (the DSP portion is not included).  
The project is divided into two main directories:
```
📁 SerDes_LoggingSystem/
├── 📂 DownholeBusControlBoard/   # 井下部分 / Downhole module
└── 📂 Surface/                   # 地面部分 / Surface module
```
---

## 编码说明 / Encoding Notice

1. **所有源文件均使用 GBK 编码存储。**  
   All source files in this project are stored using **GBK encoding**.

2. 在不支持 GBK 的环境中打开时，**注释及其他非 ASCII 文本可能会出现乱码。**  
   When opened in environments that do not support GBK, comments and other non-ASCII text may appear garbled.

3. 为确保正确显示，请将编辑器或 IDE 的编码设置为 **GBK**。  
   To ensure proper display, please configure your editor or IDE to use **GBK encoding** when opening these files.

4. 如需跨平台协作，建议将文件转换为 **UTF-8 编码** 以获得更好的兼容性。  
   For cross-platform collaboration, it is recommended to convert the files to **UTF-8 encoding** for better compatibility.

---


