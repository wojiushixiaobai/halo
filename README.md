# halo

halo jar 包, 本地部署使用


## 食用方法

环境要求: OpenJRE >= 17.0.8

```bash
# debian 或者 ubuntu 可以直接使用 apt 安装, 其他 redhat 或 centos 系统可以使用 yum 安装

apt install openjdk-17-jre-headless
```

```
# 定义工作目录和版本, 如有需要自行更换
WORKDIR=/opt/halo
VERSION=v2.10.2

mkdir -p ${WORKDIR}/build ${WORKDIR}/application

wget https://github.com/wojiushixiaobai/halo/releases/download/${VERSION}/halo-${VERSION}.tar.gz

# 解压
tar -xf halo-${VERSION}.tar.gz -C ${WORKDIR}/build --strip-components 1
cd ${WORKDIR}/build
java -Djarmode=layertools -jar application.jar extract

# 复制文件
cp -rf dependencies/* ${WORKDIR}/application
cp -rf spring-boot-loader/* ${WORKDIR}/application
cp -rf snapshot-dependencies/* ${WORKDIR}/application
cp -rf application/* ${WORKDIR}/application
```

```bash
# 启动参数, /opt/halo/data/.halo2 为持久化数据目录, 可以自行更改, 升级前后保持一致即可
cd /opt/halo/application
export JVM_OPTS="-Xmx256m -Xms256m"
export HALO_WORK_DIR="/opt/halo/data/.halo2"
export SPRING_CONFIG_LOCATION="optional:classpath:/;optional:file:opt/halo/data/.halo2"
java $JVM_OPTS org.springframework.boot.loader.JarLauncher
```

```bash
## 使用 systemd 管理 halo 服务

# create user
useradd --system --no-create-home --home-dir /opt/halo --shell /bin/false halo

# create env

cat > /opt/halo/env << "EOF"
JVM_OPTS="-Xmx256m -Xms256m"
HALO_WORK_DIR="/opt/halo/data/.halo2"
SPRING_CONFIG_LOCATION="optional:classpath:/;optional:file:opt/halo/data"
EOF

# create service
cat > /etc/systemd/system/halo.service << "EOF"
[Unit]
Description=Halo Web Server
After=network.target

[Service]
WorkingDirectory=/opt/halo/application
EnvironmentFile=-/opt/halo/env
Type=simple
ExecStart=/usr/bin/java $JVM_OPTS org.springframework.boot.loader.JarLauncher
Restart=on-failure
RestartSec=10
User=halo
Group=halo

[Install]
WantedBy=multi-user.target
EOF

# reset permission
chown -R halo:halo /opt/halo

# enable service
systemctl enable halo.service
systemctl start halo.service
```

## 参数说明

可参考官方文档 https://docs.halo.run/getting-started/install/docker-compose

```
spring.r2dbc.url            # 数据库连接地址，详细可查阅下方的 数据库配置
spring.r2dbc.username       # 数据库用户名
spring.r2dbc.password       # 数据库密码
spring.sql.init.platform    # 数据库平台名称，支持 postgresql、mysql、h2
halo.external-url           # 外部访问链接，如果需要在公网访问，需要配置为实际访问地址
halo.cache.page.disabled    # 是否禁用页面缓存，默认为禁用，如需页面缓存可以手动添加此配置，并设置为 false。

开启缓存之后，在登录的情况下不会经过缓存，且默认一个小时会清理掉不活跃的缓存，也可以在 Console 仪表盘的快捷访问中手动清理缓存。
```

数据库配置
```
链接方式      链接地址格式	                                                                     spring.sql.init.platform
PostgreSQL    r2dbc:pool:postgresql://{HOST}:{PORT}/{DATABASE}	                                postgresql
MySQL         r2dbc:pool:mysql://{HOST}:{PORT}/{DATABASE}	                                    mysql
MariaDB       r2dbc:pool:mariadb://{HOST}:{PORT}/{DATABASE}	                                    mysql
H2 Database   r2dbc:h2:file:///${halo.work-dir}/db/halo-next?MODE=MySQL&DB_CLOSE_ON_EXIT=FALSE  h2
```

### PostgreSQL

使用 PostgreSQL 数据库存储数据

```bash
java -Xmx256m -Xms256m org.springframework.boot.loader.JarLauncher \
    --spring.r2dbc.url=r2dbc:pool:postgresql://localhost/halo \
    --spring.r2dbc.password=openpostgresql \
    --spring.sql.init.platform=postgresql \
    --halo.external-url=http://localhost:8090/
```

### MySQL

使用 MySQL 数据库存储数据

```bash
java -Xmx256m -Xms256m org.springframework.boot.loader.JarLauncher \
    --spring.r2dbc.url=r2dbc:pool:mysql://localhost:3306/halo \
    --spring.r2dbc.username=root \
    --spring.r2dbc.password=o#DwN&JSa56 \
    --spring.sql.init.platform=mysql \
    --halo.external-url=http://localhost:8090/