
### 安装步骤

1. 在docker-muzi下新增文件夹/data/mysql用来映射数据库文件。

	```
	mkdir data/mysql
	```

2. docker-compose命令
可以自动完成包括构建镜像，(重新)创建服务，启动服务，并关联服务相关容器的一系列操作。
	
	```
	docker-compose up
	```

3. 进入容器执行
    ```
	docker exec -it muzi_space bash
	```
