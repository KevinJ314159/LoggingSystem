# SerDes LoggingSystem

## 项目说明 / Project Description

此项目为鄙人的本科毕业设计。项目使用 **FPGA、DSP、BOSA (Bi-Directional Optical Sub-Assembly)** 组件，  
实现了一套能够达到 **上行 10 Mbps（井下到地面回传数据）**、**下行 500 Kbps（地面到井下下发指令）** 的 **全双工通信系统**。

This project was my **undergraduate thesis**, which implemented a **full-duplex communication system** using **FPGA, DSP, and BOSA (Bi-Directional Optical Sub-Assembly)** modules.  
It achieved an **uplink data rate of 10 Mbps (from downhole to surface)** and a **downlink rate of 500 Kbps (from surface to downhole)**.

![测井通信系统结构图 System Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%872.jpg)
![地面FPGA结构图 Surface FPGA Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%872.jpg)

---

## 文件结构 / Project Structure

本项目包含通信系统中 **FPGA 部分的 Verilog 代码**，不包含 DSP 部分代码。
This repository contains **only the FPGA-side Verilog source code** (the DSP portion is not included).

内容分为4个主要文件夹，其中DownholeBusControlBoard及Surface中为Verilog源码，所有配套testbench均以 "_tb"后缀结尾；FiberSurfaceCommBoard_top及BusControlBoard_top中为Vivado工程文件夹，可以直接使用Vivado 2018.3打开其中**.xpr**文件以直接预览工程。

  
The project is organized into four folders.
Among them, DownholeBusControlBoard and Surface contain the Verilog source code, and all corresponding testbenches are named with the suffix "_tb".
The folders FiberSurfaceCommBoard_top and BusControlBoard_top contain the Vivado project files, where the .xpr files can be opened directly in Vivado 2018.3 to preview the projects.

```
📁 SerDes_LoggingSystem/
├── 📂 DownholeBusControlBoard/   # 井下部分verilog源文件 / Downhole modules verilog sources files
├── 📂 Surface/                   # 地面部分verilog源文件 / Surface modules verilog sources files
├── 📂 FiberSurfaceCommBoard_top/ # 地面部分Vivado工程文件 / Surface Vivado project folder
└── 📂 BusControlBoard_top/       # 井下部分Vivado工程文件 / Downhole Vivado project folder
```
---

## 使用说明 / Usage Instructions

1. 项目使用**Vivado 2018.3**搭建，使用**Libero Soc 11.9**进行烧录。行为仿真及综合后仿真使用Vivado以及Modulesim平台完成。
   All source files in this project are stored using **GBK encoding**.

2. 在不支持 GBK 的环境中打开时，**注释及其他非 ASCII 文本可能会出现乱码。**  
   When opened in environments that do not support GBK, comments and other non-ASCII text may appear garbled.

3. 为确保正确显示，请将编辑器或 IDE 的编码设置为 **GBK**。  
   To ensure proper display, please configure your editor or IDE to use **GBK encoding** when opening these files.

4. 如需跨平台协作，建议将文件转换为 **UTF-8 编码** 以获得更好的兼容性。  
   For cross-platform collaboration, it is recommended to convert the files to **UTF-8 encoding** for better compatibility.

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


