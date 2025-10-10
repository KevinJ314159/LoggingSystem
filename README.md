# SerDes LoggingSystem

## 项目说明 / Project Description

此项目为鄙人的本科毕业设计。项目使用 **FPGA、DSP、BOSA (Bi-Directional Optical Sub-Assembly)** 组件，  
实现了一套能够达到 **上行 10 Mbps（井下到地面回传数据）**、**下行 500 Kbps（地面到井下下发指令）** 的 **全双工通信系统**。<br>
This project was my **undergraduate thesis**, which implemented a **full-duplex communication system** using **FPGA, DSP, and BOSA (Bi-Directional Optical Sub-Assembly)** modules.  
It achieved an **uplink data rate of 10 Mbps (from downhole to surface)** and a **downlink rate of 500 Kbps (from surface to downhole)**.

**测井通信系统结构图 System Strcture:**
![测井通信系统结构图 System Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%872.jpg)

**地面FPGA结构图 Surface FPGA Strcture:**
![地面FPGA结构图 Surface FPGA Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%873.jpg)

**井下FPGA结构图 Downhole FPGA Strcture:**
![井下FPGA结构图 Downhole FPGA Strcture](https://github.com/KevinJ314159/LoggingSystem/blob/master/image/%E5%9B%BE%E7%89%874.jpg)

---

## 文件结构 / Project Structure

本项目包含通信系统中 **FPGA 部分的 Verilog 代码**，不包含 DSP 部分代码。<br>
This repository contains **only the FPGA-side Verilog source code** (the DSP portion is not included).

内容分为4个主要文件夹位于**master**分支中，其中DownholeBusControlBoard及Surface中为Verilog源码，所有配套testbench均以 "_tb"后缀结尾；FiberSurfaceCommBoard_top及BusControlBoard_top中为Vivado工程文件夹，可以直接使用Vivado 2018.3打开其中**.xpr**文件以直接预览工程。<br>
The project is organized into four folders in **master** branch.
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

1. **克隆仓库 (Clone the Repository)**
   
   使用下面命令将此项目下载到本地：<br>
   Use the following command to download this project to your local:
   
   git clone https://github.com/KevinJ314159/LoggingSystem.git
   
3. **预览与使用(Preview and Usage)**
   
   项目使用**Vivado 2018.3**搭建，使用**Libero Soc 11.9**进行烧录。行为仿真及综合后仿真使用Vivado以及Modulesim平台完成。
   您可以使用**Vivado 2018.3**打开**FiberSurfaceCommBoard_top**以及**BusControlBoard_top**中的**.xpr**文件直接查看工程，这也是推荐的方法。<br>
   The project is built using **Vivado 2018.3** and programmed using **Libero SoC 11.9**. Behavioral simulation and post-synthesis simulation are performed on Vivado and ModelSim platforms.
   You can open the **.xpr** files in **FiberSurfaceCommBoard_top** and **BusControlBoard_top** directly in **Vivado 2018.3** to view the project, which is also the recommended method.
---

## 文件编码格式说明 / Encoding Notice

1. **所有源文件均使用 GBK 编码存储。**  
   All source files in this project are stored using **GBK encoding**.

2. 在不支持 GBK 的环境中打开时，**注释及其他非 ASCII 文本可能会出现乱码。**  
   When opened in environments that do not support GBK, comments and other non-ASCII text may appear garbled.

3. 为确保正确显示，请将编辑器或 IDE 的编码设置为 **GBK**。  
   To ensure proper display, please configure your editor or IDE to use **GBK encoding** when opening these files.

4. 如需跨平台协作，建议将文件转换为 **UTF-8 编码** 以获得更好的兼容性。  
   For cross-platform collaboration, it is recommended to convert the files to **UTF-8 encoding** for better compatibility.
---

## 特别致谢 / Special Thanks

特别感谢电子科技大学信息与通信工程学院 顾庆水 教授（guqs@uestc.edu.cn）的指导与帮助。<br>
I would like to express my sincere gratitude to Professor Gu Qingshui（guqs@uestc.edu.cn）from the School of Information and Communication Engineering, University of Electronic Science and Technology of China, for his guidance and support.

