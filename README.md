# SerDes LoggingSystem

项目说明：此项目为鄙人本科毕设，项目使用FPGA、DSP、BOSA(Bi-Directional Optical Sub-Assembly)组件实现了一套能够达到上行10Mbps速率（井下到地面回传数据），下行500Kbps（地面到井下下发指令）的全双工通信系统。
Introdction: This project was my undergraduate thesis. It implemented a full-duplex communication system using FPGA, DSP, and BOSA (Bi-Directional Optical Sub-Assembly) components, achieving an uplink data rate of 10 Mbps (from downhole to the surface) and a downlink rate of 500 Kbps (from the surface to downhole).

包含内容：此项目包含通信系统组件中的FPGA部分Verilog代码，不包含DSP部分代码。内容分为DownholeBusControlBoard 和 Surface 两个文件夹，前者为井下部分，后者为地面部分。

1）All source files in this project are stored using GBK encoding.
   本工程中的所有源文件均使用 GBK 编码存储。

   When opened in environments that do not support GBK, comments and other non-ASCII text may appear garbled.
   在不支持 GBK 的环境中打开时，注释及其他非 ASCII 文本可能会出现乱码。

   To ensure correct display, please configure your editor or IDE to use GBK encoding when opening these files.
   为确保正确显示，请在打开这些文件时将编辑器或 IDE 的编码设置为 GBK。

   If cross-platform collaboration is required, it is recommended to convert the files to UTF-8 encoding for better compatibility.
   如需跨平台协作，建议将文件转换为 UTF-8 编码，以获得更好的兼容性。
