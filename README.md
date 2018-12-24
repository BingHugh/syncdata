# syncdata
to keep data synchronized before start slave in mysql

简要说明：
    开启主从复制之前，必须要确保master端和slave端的同步表数据一致，利用本脚本可以自动完成此功能。

操作说明：
1. 将本文件夹所有文件拷贝到mysql服务器上
2. 根据实际情况，修改配置文件host.cnf
3. 执行autoSync.sh
