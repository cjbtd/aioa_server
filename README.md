# AIOA Server

* AIOA 后端部分，基于 Django
* 仅使用SQL就能开发大量业务模块，系统大部分功能是动态可配置的，流程如下：
    - 创建数据库对象（数据库层面）
        + 表或视图（实体）
        + 触发器（业务逻辑）
    - 添加模块和配置（系统层面）
        + 菜单和模块
        + 模块配置
        + 分配权限
* 现有功能无法满足的情况下，可自行扩展前后端
* [线上地址](https://www.chenjiabintd.com)
    - 现有账号：admin、100001、100002、100003、100004
    - 所有账号初始密码是：123456
    - 系统每日凌晨自动重置，届时所有数据将恢复如初
    - 具体使用手册请登录系统后查看[通知](https://www.chenjiabintd.com/datacenter/notice?_init_rel=2)

## Getting Started

* See [init.md](./conf/init.md)

## Features

* See [features.md](./conf/features.md)

## Env

* See [env.md](./conf/env.md)
