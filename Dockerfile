ARG PG_MAJOR=17
FROM postgres:$PG_MAJOR
ARG PG_MAJOR

# 安装编译依赖
RUN apt-get update && \
		apt-mark hold locales && \
		apt-get install -y --no-install-recommends build-essential postgresql-server-dev-$PG_MAJOR cmake

# 复制 pgvector 源码
COPY ./pgvector /tmp/pgvector

# 编译安装 pgvector
RUN		cd /tmp/pgvector && \
		make clean && \
		make -j8 OPTFLAGS="" && \
		make install && \
		mkdir /usr/share/doc/pgvector && \
		cp LICENSE README.md /usr/share/doc/pgvector && \
		rm -r /tmp/pgvector 

# 复制 timescaledb 源码
COPY ./timescaledb /tmp/timescaledb

# 编译安装 timescaledb
RUN cd /tmp/timescaledb && \
		./bootstrap && \
		cd /tmp/timescaledb/build && \
		make -j8 && \
		make install && \
		rm -r /tmp/timescaledb

# 配置 timescaledb
RUN echo "shared_preload_libraries = 'timescaledb'" >> /usr/share/postgresql/postgresql.conf.sample

# 清理
RUN		apt-get remove -y build-essential postgresql-server-dev-$PG_MAJOR cmake && \
		apt-get autoremove -y && \
		apt-mark unhold locales && \
		rm -rf /var/lib/apt/lists/*
