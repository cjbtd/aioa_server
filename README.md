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

## Example

- Create Table, See [通知](https://www.chenjiabintd.com/datacenter/notice?_init_rel=2)

```sql
-- ============================================================
-- Author      : Dawn
-- Create date : 2022-05-20
-- Description : xx表
-- ============================================================
CREATE TABLE `T_XX_XXX`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    -- The above columns are required
    ,`COL1` VARCHAR(32)
    ,`COL2` VARCHAR(1024)
    ,`COL3` CHAR(1)
    ,`COL4` TEXT
    ,CONSTRAINT `PK_T_SYSTEM_FEEDBACK` PRIMARY KEY (ID)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_STATUS`(`STATUS`)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_I_NAME`(`I_NAME`)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_I_DT`(`I_DT`)
);
```

- Add Menu and Module, See [通知](https://www.chenjiabintd.com/datacenter/notice?_init_rel=2)
- Add Config, See [datacenter.json](https://github.com/cjbtd/aioa_server/blob/main/conf/datacenter.json)

```json
{
  "obj": "`T_XX_XXX`",
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "COL1": {
      "label": "显示名称"
    },
    "COL2": {},
    "COL3": {},
    "COL4": {
      "type": "text"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  }
}
```

- Add Perm, See [权限管理](https://www.chenjiabintd.com/system/perms)
