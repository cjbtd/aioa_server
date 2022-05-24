-- VIEW TABLE TRIGGER FUNCTION PROCEDURE
-- use root

SET GLOBAL log_bin_trust_function_creators=1;

DELIMITER ;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2019-04-01
-- Description : 打印数据库对象创建规范
-- Modify [1]  : Dawn, 2021-04-21, 适配MySQL
-- ============================================================
CREATE PROCEDURE `SP_`(IN p_TABLE_NAME VARCHAR(128))
BEGIN
    DECLARE v_SQL_TEXT TEXT;

    SET v_SQL_TEXT = CONCAT('
-- 用四个空格代替TAB
-- 表名和字段名均大写，取名优先顺序为：单词、简称、拼音，多个使用【_】连接
-- 表名以【T_】开头，一类表的前缀必须一致，例如：T_SYSTEM_...、T_COMPANY_...
-- 建表默认有：
--     ID      自增长主键
--     GID,    数据分组码
--     STATUS  数据状态码
--     I_DT    录入时间
--     U_DT    更新时间
--     V_DT    审核时间
--     I_NAME  录入者
--     U_NAME  更新者
--     V_NAME  审核者

-- ============================================================
-- Author      : Dawn
-- Create date : 1900-01-01
-- Description : ...
-- Modify [1]  : Dawn, 2000-01-01, ...
-- ============================================================
CREATE TABLE `', p_TABLE_NAME, '`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT ''0''
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT ''system''
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`GS` VARCHAR(128)
	,`BM` VARCHAR(128)
	,`GW` VARCHAR(128)
	,`SQ` VARCHAR(16)
	,`HD` VARCHAR(16)
	,`ZG` VARCHAR(16)
	,`SP` VARCHAR(16)
	,`FH` VARCHAR(16)
	,`CN` VARCHAR(16)
	,`TO` VARCHAR(256)
	,`CC` VARCHAR(256)
	,`SIGN` VARCHAR(16)
	,`STAMP` CHAR(1)
	,`DF` TEXT
    ,CONSTRAINT `PK_', p_TABLE_NAME, '` PRIMARY KEY (ID)
    ,CONSTRAINT `FK_', p_TABLE_NAME, '` FOREIGN KEY (`COL0`) REFERENCES `TB` (`COL`) ON ...
    ,UNIQUE INDEX `AK_', p_TABLE_NAME, '`(`COL0`, `COL1`, `COL2`)
	,INDEX `IX_', p_TABLE_NAME, '_GID`(`GID`)
    ,INDEX `IX_', p_TABLE_NAME, '_STATUS`(`STATUS`)
    ,INDEX `IX_', p_TABLE_NAME, '_I_NAME`(`I_NAME`)
    ,INDEX `IX_', p_TABLE_NAME, '_I_DT`(`I_DT`)
);

-- 创建视图【View】，CREATE VIEW V_*
-- 创建触发器【Trigger】，CREATE TRIGGER TR_*
-- 创建存储过程【Stored Procedure】，CREATE PROCEDURE SP_*
');

    SELECT v_SQL_TEXT;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 生成MySQL辅助表
-- ============================================================
CREATE PROCEDURE `SP_CREATE_AUXILIARY`()
BEGIN
    DECLARE v_TOTAL INT;

    DROP TABLE IF EXISTS T_SYSTEM_AUXILIARY;

    CREATE TABLE `T_SYSTEM_AUXILIARY`
    (
        `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `GID`    INT UNSIGNED NOT NULL DEFAULT 0,
        `STATUS` CHAR(1)      NOT NULL DEFAULT '0',
        `I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `U_DT`   DATETIME,
        `V_DT`   DATETIME,
        `I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system',
        `U_NAME` VARCHAR(8),
        `V_NAME` VARCHAR(8),
        `NUM`    INT UNSIGNED NOT NULL,
        `TYPE`   CHAR(1) COMMENT 'P：0-2048连续的数值，0：偶数，1：奇数，2：2的次方',
        CONSTRAINT `PK_T_SYSTEM_AUXILIARY` PRIMARY KEY (ID),
        INDEX `IX_T_SYSTEM_AUXILIARY_2` (`NUM`, `TYPE`)
    );

    SET v_TOTAL = 0;
    WHILE v_TOTAL <= 2048
        DO
            INSERT INTO `T_SYSTEM_AUXILIARY`(`NUM`, `TYPE`) VALUES (v_TOTAL, 'P');
            SET v_TOTAL = v_TOTAL + 1;
        END WHILE;

    SET v_TOTAL = 0;
    WHILE v_TOTAL <= 2048
        DO
            INSERT INTO `T_SYSTEM_AUXILIARY`(`NUM`, `TYPE`) VALUES (v_TOTAL, '0');
            SET v_TOTAL = v_TOTAL + 2;
        END WHILE;

    SET v_TOTAL = 1;
    WHILE v_TOTAL <= 2048
        DO
            INSERT INTO `T_SYSTEM_AUXILIARY`(`NUM`, `TYPE`) VALUES (v_TOTAL, '1');
            SET v_TOTAL = v_TOTAL + 2;
        END WHILE;

    SET v_TOTAL = 2;
    WHILE v_TOTAL <= 2048
        DO
            INSERT INTO `T_SYSTEM_AUXILIARY`(`NUM`, `TYPE`) VALUES (v_TOTAL, '2');
            SET v_TOTAL = v_TOTAL * 2;
        END WHILE;
END;

;;;

CALL `SP_CREATE_AUXILIARY`();

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2019-04-01
-- Description : 同步数据表和数据字典
-- ============================================================
CREATE PROCEDURE `SP_SYNC_DB_OBJ`()
BEGIN
    INSERT INTO `base_databook`(`db`, `table`, `enable`, `edt`, `udt`)
    SELECT `TABLE_SCHEMA`
          ,`TABLE_NAME`
          ,1
          ,CURRENT_TIMESTAMP
          ,CURRENT_TIMESTAMP
      FROM information_schema.TABLES a
     WHERE `TABLE_SCHEMA` = 'aioa'
           AND `TABLE_TYPE` = 'BASE TABLE'
           AND NOT EXISTS(
               SELECT 1 FROM `base_databook` b WHERE b.db = 'aioa' AND a.TABLE_NAME = b.`table`
           );

    UPDATE `base_databook` b
       SET `enable` = 0
     WHERE NOT EXISTS(
               SELECT 1
                 FROM information_schema.TABLES a
                WHERE a.`TABLE_SCHEMA` =  b.`db`
                      AND a.`TABLE_NAME` = b.`table`
                      AND a.`TABLE_TYPE` = 'BASE TABLE'
           );

    INSERT INTO `base_datadict` (`column`, `column_id`, `column_type`, `column_length`, `is_pk`, `is_null`, `is_incr`, `default`, `status`, `edt`, `udt`, `table_id`)
    SELECT a.`COLUMN_NAME`
          ,a.`ORDINAL_POSITION`
          ,a.`DATA_TYPE`
          ,IFNULL(IF(a.`CHARACTER_MAXIMUM_LENGTH` <= 65535, a.`CHARACTER_MAXIMUM_LENGTH`, 0), '')
          ,a.`COLUMN_KEY` = 'PRI'
          ,a.`IS_NULLABLE` = 'YES'
          ,a.`EXTRA` = 'auto_increment'
          ,a.`COLUMN_DEFAULT`
          ,'0'
          ,CURRENT_TIMESTAMP
          ,CURRENT_TIMESTAMP
          ,b.`id`
      FROM information_schema.COLUMNS a
           INNER JOIN
           `base_databook` b
               ON a.`TABLE_SCHEMA` = b.`db`
                  AND a.`TABLE_NAME` = b.`table`
     WHERE NOT EXISTS (
               SELECT 1 FROM `base_datadict` c WHERE c.`table_id` = b.`id` AND c.`column` = a.`COLUMN_NAME`
           )
    ORDER BY a.`TABLE_NAME`, a.`ORDINAL_POSITION`;

    -- 不一致
    UPDATE `base_datadict` c
       SET `status` = '2'
     WHERE `status` = '1'
           AND EXISTS(
               SELECT 1
                 FROM information_schema.COLUMNS a
                      INNER JOIN
                      `base_databook` b
                          ON a.`TABLE_SCHEMA` = b.`db`
                             AND a.`TABLE_NAME` = b.`table`
                WHERE c.`table_id` = b.`id`
                      AND c.`column` = a.`COLUMN_NAME`
                      AND (
                          c.`column_type` <> a.`DATA_TYPE`
                          OR c.`column_length` <> IFNULL(IF(a.`CHARACTER_MAXIMUM_LENGTH` <= 65535, a.`CHARACTER_MAXIMUM_LENGTH`, 0), '')
                          OR c.`is_pk` <> a.`COLUMN_KEY` = 'PRI'
                          OR c.`is_null` <> a.`IS_NULLABLE` = 'YES'
                          OR c.`is_incr` <> a.`EXTRA` = 'auto_increment'
                          OR c.`default` <> a.`COLUMN_DEFAULT`
                      )
           );

    -- 已删除
    UPDATE `base_datadict` c
       SET `status` = '4'
     WHERE `status` = '1'
           AND NOT EXISTS(
               SELECT 1
                 FROM information_schema.COLUMNS a
                      INNER JOIN
                      `base_databook` b
                          ON a.`TABLE_SCHEMA` = b.`db`
                             AND a.`TABLE_NAME` = b.`table`
                WHERE c.`table_id` = b.`id`
                      AND c.`column` = a.`COLUMN_NAME`
           );
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2019-04-01
-- Description : 合并数据表和数据字典
-- ============================================================
CREATE PROCEDURE `SP_MERGE_DB_OBJ`()
BEGIN
UPDATE `base_datadict` c, information_schema.COLUMNS a, `base_databook` b
   SET c.`status` = '1'
      ,c.`column_type` = a.`DATA_TYPE`
      ,c.`column_length` = IFNULL(IF(a.`CHARACTER_MAXIMUM_LENGTH` <= 65535, a.`CHARACTER_MAXIMUM_LENGTH`, 0), '')
      ,c.`is_pk` = a.`COLUMN_KEY` = 'PRI'
      ,c.`is_null` = a.`IS_NULLABLE` = 'YES'
      ,c.`is_incr` = a.`EXTRA` = 'auto_increment'
      ,c.`default` = a.`COLUMN_DEFAULT`
 WHERE c.`status` = '2'
       AND a.`TABLE_SCHEMA` = b.`db`
       AND a.`TABLE_NAME` = b.`table`
       AND c.`table_id` = b.`id`
       AND c.`column` = a.`COLUMN_NAME`;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2022-04-21
-- Description : 统计字符串出现的次数
-- ============================================================
CREATE FUNCTION `FN_COUNT_STR`(
    p_TEXT TEXT
   ,p_STR TEXT
)
    RETURNS INT
BEGIN
    SET p_TEXT = IFNULL(p_TEXT, '');
    SET p_STR = IFNULL(p_STR, ',');
    RETURN (LENGTH(p_TEXT) - LENGTH(REPLACE(p_TEXT, p_STR, '')));
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2022-04-21
-- Description : 显示账号名称
-- ============================================================
CREATE FUNCTION `FN_GET_USER_NAME`(
    p_USERNAMES TEXT
)
    RETURNS TEXT
BEGIN
    DECLARE v_SEP CHAR(1) DEFAULT ',';

    RETURN (
        SELECT GROUP_CONCAT(CONCAT(`username`, '(', `first_name`, ')') SEPARATOR ';')
          FROM `auth_user`
         WHERE `username` IN (
                   SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_USERNAMES, v_SEP, `NUM` + 1), v_SEP, -1))
                     FROM `T_SYSTEM_AUXILIARY`
                    WHERE `NUM` <= FN_COUNT_STR(p_USERNAMES, v_SEP)
                          AND `TYPE` = 'P'
        )
    );
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2022-04-21
-- Description : 显示角色名称
-- ============================================================
CREATE FUNCTION `FN_GET_ROLE_NAME`(
    p_IDS TEXT
)
    RETURNS TEXT
BEGIN
    DECLARE v_SEP CHAR(1) DEFAULT ',';

    RETURN (
        SELECT GROUP_CONCAT(`name` SEPARATOR ';')
          FROM `base_role`
         WHERE `id` IN (
                   SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_IDS, v_SEP, `NUM` + 1), v_SEP, -1))
                     FROM `T_SYSTEM_AUXILIARY`
                    WHERE `NUM` <= FN_COUNT_STR(p_IDS, v_SEP)
                          AND `TYPE` = 'P'
        )
    );
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 通过账号获取有效的工号
-- ============================================================
CREATE FUNCTION `FN_GET_USERNAME_BY_STAFF_ID`(
    p_USERNAME VARCHAR(8)
)
    RETURNS VARCHAR(32)
BEGIN
    RETURN (
        SELECT IFNULL(`FULL_NAME`, p_USERNAME)
          FROM `T_COMPANY_STAFF`
         WHERE `STATUS` = '1'
               AND `STAFF_ID` = p_USERNAME
    );
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 有效账号的有效模块及权限，列名顺序不可更改
-- ============================================================
CREATE VIEW `V_USER_MODULES`
AS
WITH cte_perms AS (
  SELECT rp.`id`,`user`,`module_id`,`perm_config_id`
    FROM `base_userrole` rr
         INNER JOIN
         `base_role` r
             ON r.`id` = rr.`role_id`
         INNER JOIN
         `base_roleperm` rp
             ON rp.`role_id` = r.`id`
   WHERE rr.`enable` = 1
         AND r.`enable` = 1
         AND rp.`enable` = 1
UNION ALL
  SELECT 99999999,`user`,`module_id`,`perm_config_id`
    FROM `base_userperm` up
   WHERE up.`enable` = 1
)
,cte_userperms AS (
  SELECT `user`
        ,`module_id`
        ,`perm_config_id`
    FROM (
          SELECT ROW_NUMBER() OVER(PARTITION BY `user`,`module_id` ORDER BY `id` DESC) idx
                ,`user`
                ,`module_id`
                ,`perm_config_id`
            FROM cte_perms
         ) t
   WHERE idx = 1
)
,cte_usermodules AS (
  SELECT `user`
        ,me.`sort` AS menu_sort
        ,me.`id` AS menu_id
        ,mo.`sort` AS module_sort
        ,mo.`id` AS module_id
        ,`path`
        ,`name`
        ,`meta`
        ,`relations`
        ,`label`
        ,`value`
        ,`base_config_id`
        ,`over_config_id`
        ,`spec_config_id`
        ,`perm_config_id`
    FROM `base_menu` me
         INNER JOIN
         `base_module` mo
             ON mo.`menu_id` = me.`id`
         INNER JOIN
         cte_userperms up
             ON up.module_id = mo.`id`
   WHERE me.`enable` = 1
         AND mo.`enable` = 1
)

SELECT * FROM cte_usermodules;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 用户角色
-- ============================================================
CREATE VIEW `V_USER_ROLE`
AS
SELECT `name`
      ,`user`
  FROM `base_role` r
       INNER JOIN
       `base_userrole` ur
           ON r.`id` = ur.`role_id`
 WHERE r.`enable` = 1
       AND ur.`enable` = 1;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工关系
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF_RELATION`
(
    `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `GID`    INT UNSIGNED NOT NULL DEFAULT 0,
    `STATUS` CHAR(1)      NOT NULL DEFAULT '0',
    `I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system',
    `U_NAME` VARCHAR(8),
    `V_NAME` VARCHAR(8),
    `I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `U_DT`   DATETIME,
    `V_DT`   DATETIME,
    `STAFF_ID`     VARCHAR(8) NOT NULL,
    `STAFF_ID_L`   VARCHAR(8) NOT NULL,
    CONSTRAINT `PK_T_COMPANY_STAFF_RELATION` PRIMARY KEY (ID),
    UNIQUE INDEX `AK_T_COMPANY_STAFF_RELATION` (`STAFF_ID`, `STAFF_ID_L`),
    INDEX `IX_T_COMPANY_STAFF_RELATION_STATUS` (`STATUS`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工关系查询视图
-- ============================================================
CREATE VIEW `V_COMPANY_STAFF_RELATION`
AS
WITH RECURSIVE cte_t_company_staff_relation AS(
SELECT `STAFF_ID`
      ,`STAFF_ID_L`
      ,1 AS `RANK`
  FROM `T_COMPANY_STAFF_RELATION`
 WHERE `STATUS` = '1'
UNION ALL
SELECT a.`STAFF_ID`
      ,b.`STAFF_ID_L`
      ,b.`RANK` + 1 AS `RANK`
  FROM `T_COMPANY_STAFF_RELATION` a
       INNER JOIN
       cte_t_company_staff_relation b
           ON a.`STATUS` = '1'
              AND a.`STAFF_ID_L` = b.`STAFF_ID`
)

SELECT DISTINCT `STAFF_ID`
      ,`STAFF_ID_L`
      ,DENSE_RANK() OVER(PARTITION BY STAFF_ID ORDER BY `RANK` DESC) `RANK`
      ,`RANK` `RANK_DESC`
  FROM cte_t_company_staff_relation;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 通讯录
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`STAFF_ID` VARCHAR(8)
    ,`POSITION` VARCHAR(1024)
	,`LEADERS` VARCHAR(128)
	,`FULL_NAME` VARCHAR(32)
	,`ABBR_NAME` VARCHAR(32)
	,`EMAIL` VARCHAR(128)
	,`TEL` VARCHAR(64)
	,`MP` VARCHAR(64)
	,`ROLES` TEXT
	,`REMARK` VARCHAR(1024)
	,`IP` VARCHAR(15)
    ,CONSTRAINT `PK_T_COMPANY_STAFF` PRIMARY KEY (ID)
    ,UNIQUE INDEX `AK_T_COMPANY_STAFF`(`STAFF_ID`)
	,INDEX `IX_T_COMPANY_STAFF_GID`(`GID`)
    ,INDEX `IX_T_COMPANY_STAFF_STATUS`(`STATUS`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 待办事项
-- ============================================================
CREATE TABLE `T_COMPANY_TODO`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`TAG` VARCHAR(16)
	,`CONTENT` VARCHAR(1024)
	,`ATTACHMENTS` TEXT
	,`PRIORITY` INT
	,`URL` VARCHAR(1024)
    ,CONSTRAINT `PK_T_COMPANY_TODO` PRIMARY KEY (ID)
    ,INDEX `IX_T_COMPANY_TODO_STATUS`(`STATUS`)
    ,INDEX `IX_T_COMPANY_TODO_I_NAME`(`I_NAME`)
    ,INDEX `IX_T_COMPANY_TODO_TAG`(`TAG`)
    ,INDEX `IX_T_COMPANY_TODO_PRIORITY`(`PRIORITY`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 日程管理和节假日
-- ============================================================
CREATE TABLE `T_COMPANY_CALENDAR`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`NAME` VARCHAR(16)
	,`BEGIN_DT` DATETIME
	,`END_DT` DATETIME
	,`CLS` CHAR(1)
	,`WARN_DAY` INT
	,`WARN_TIMES` INT
	,`GROUPS` VARCHAR(128)
	,`REMARK` TEXT
    ,CONSTRAINT `PK_T_COMPANY_CALENDAR` PRIMARY KEY (ID)
    ,UNIQUE INDEX `AK_T_COMPANY_CALENDAR`(`NAME`, `BEGIN_DT`, `END_DT`)
    ,INDEX `IX_T_COMPANY_CALENDAR_STATUS`(`STATUS`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 公告通知
-- ============================================================
CREATE TABLE `T_COMPANY_NOTICE`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`TITLE` VARCHAR(128)
	,`GROUPS` VARCHAR(128)
	,`CONTENT` TEXT
	,`READERS` TEXT
    ,CONSTRAINT `PK_T_COMPANY_NOTICE` PRIMARY KEY (ID)
    ,INDEX `IX_T_COMPANY_NOTICE_STATUS`(`STATUS`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 生成待办事项
-- ============================================================
CREATE PROCEDURE `SP_ADD_TODO_LIST`(
     IN p_USERS VARCHAR(1024)
    ,IN p_TAG VARCHAR(16)
    ,IN p_CONTENT VARCHAR(1024)
    ,IN p_URL VARCHAR(1024)
    ,IN p_PRIORITY INT
)
BEGIN
    DECLARE v_SEP CHAR(1) DEFAULT ',';

    IF p_USERS IS NULL THEN
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定账号';
    END IF;

    IF p_TAG IS NULL THEN
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定标签';
    END IF;

    IF p_CONTENT IS NULL THEN
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定内容';
    END IF;

    INSERT INTO `T_COMPANY_TODO`(`I_NAME`, `TAG`, `CONTENT`, `PRIORITY`, `URL`)
    SELECT DISTINCT TRIM(value), p_TAG, p_CONTENT, p_PRIORITY, p_URL
    FROM (
             SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_USERS, v_SEP, `NUM` + 1), v_SEP, -1)) AS value
               FROM `T_SYSTEM_AUXILIARY`
              WHERE `NUM` <= FN_COUNT_STR(p_USERS, v_SEP)
                    AND `TYPE` = 'P'
         ) T
    WHERE TRIM(value) <> '';
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 生成待办事项
-- ============================================================
CREATE PROCEDURE `SP_ADD_TODO_LIST_FOR_TRIGGER`(
     IN p_USERNAMES VARCHAR(1024)
    ,IN p_ROLENAMES VARCHAR(1024)
    ,IN p_STAFF_ID VARCHAR(8)
    ,IN p_RANK INT
    ,IN p_TAG VARCHAR(16)
    ,IN p_CONTENT VARCHAR(1024)
    ,IN p_URL VARCHAR(1024) -- 必须唯一，代表一个待办事项
    ,IN p_USERNAME VARCHAR(8) -- 审核者
)
BEGIN
    DECLARE v_SEP CHAR(1) DEFAULT ',';
    DECLARE v_ALL_USERS VARCHAR(1024);

    UPDATE `T_COMPANY_TODO` SET `STATUS` = '1', `V_NAME` = p_USERNAME WHERE `URL` = p_URL AND `STATUS` = '0';

    CREATE TEMPORARY TABLE tmp_users(`username` VARCHAR(8));

    IF p_USERNAMES IS NOT NULL THEN
        INSERT INTO tmp_users(`username`)
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_USERNAMES, v_SEP, `NUM` + 1), v_SEP, -1))
        FROM `T_SYSTEM_AUXILIARY`
        WHERE `NUM` <= FN_COUNT_STR(p_USERNAMES, v_SEP)
          AND `TYPE` = 'P';
    END IF;

    IF p_ROLENAMES IS NOT NULL THEN
        INSERT INTO tmp_users(`username`)
        SELECT `user`
          FROM `base_userrole`
         WHERE `enable` = 1
                AND `role_id` IN (
                    SELECT `id`
                      FROM `base_role`
                     WHERE `enable` = 1
                            AND `name` in (
                                SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p_ROLENAMES, v_SEP, `NUM` + 1), v_SEP, -1))
                                  FROM `T_SYSTEM_AUXILIARY`
                                 WHERE `NUM` <= FN_COUNT_STR(p_ROLENAMES, v_SEP)
                                       AND `TYPE` = 'P'
                            )
                );
    END IF;

    IF p_STAFF_ID IS NOT NULL THEN
        INSERT INTO tmp_users(`username`)
        SELECT `STAFF_ID_L`
          FROM `V_COMPANY_STAFF_RELATION`
         WHERE `STAFF_ID` = p_STAFF_ID
               AND `RANK` = (
                   SELECT MAX(`RANK`)
                     FROM V_COMPANY_STAFF_RELATION
                    WHERE `STAFF_ID` = p_STAFF_ID
                          AND `RANK` <= p_RANK
               );
    END IF;

    SET v_ALL_USERS = (SELECT GROUP_CONCAT(`username`) FROM tmp_users WHERE `username` <> '');

    IF v_ALL_USERS IS NOT NULL THEN
        CALL `SP_ADD_TODO_LIST`(v_ALL_USERS, p_TAG, p_CONTENT, p_url, 100);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 计算两个时间范围的交叉部分
--               p_type: 0 - second；1 - minute；2 - hour；3 - day
-- ============================================================
CREATE FUNCTION `FN_CALC_DT_RANGE_DIFF`(
     p_DT_1_B DATETIME
    ,p_DT_1_E DATETIME
    ,p_DT_2_B DATETIME
    ,p_DT_2_E DATETIME
    ,p_TYPE INT
)
RETURNS INT
BEGIN
    DECLARE total INT DEFAULT 0;

    IF p_DT_1_B <= p_DT_2_E AND p_DT_1_E >= p_DT_2_B THEN
        IF p_DT_1_B < p_DT_2_B THEN
            SET p_DT_1_B = p_DT_2_B;
        END IF;

        IF p_DT_1_E > p_DT_2_E THEN
            SET p_DT_1_E = p_DT_2_E;
        END IF;

        IF p_TYPE = 0 THEN
            SET total = TIMESTAMPDIFF(SECOND, p_DT_1_B, p_DT_1_E);
        END IF;

        IF p_TYPE = 1 THEN
            SET total = TIMESTAMPDIFF(MINUTE, p_DT_1_B, p_DT_1_E);
        END IF;

        IF p_TYPE = 2 THEN
            SET total = TIMESTAMPDIFF(HOUR, p_DT_1_B, p_DT_1_E);
        END IF;

        IF p_TYPE = 3 THEN
            SET total = TIMESTAMPDIFF(DAY, p_DT_1_B, p_DT_1_E);
        END IF;
    END IF;

    RETURN total;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 计算工时的函数，两种类型：请假与加班
--               请假：统计时间范围内工作时间
--               加班：统计时间范围内非工作时间
--               因调休而上班的特殊日子，中午也有一个小时休息时间
--               这里是第二种方法，直接逻辑判断，整体逻辑是统计时间范围内的工作时间
-- ============================================================
CREATE FUNCTION `FN_CALC_WORK_MINUTE`(
     p_INIT_BEGIN_DT DATETIME
    ,p_INIT_END_DT DATETIME
    ,p_IS_WORK BIT -- 1：请假，0：加班
)
    RETURNS INT
BEGIN
    DECLARE v_DEFAULT_BEGIN_WORK_TIME TIME DEFAULT '08:30:00';
    DECLARE v_DEFAULT_END_WORK_TIME TIME DEFAULT '17:30:00';
    DECLARE v_DEFAULT_BEGIN_REST_TIME TIME DEFAULT '12:00:00';
    DECLARE v_DEFAULT_END_REST_TIME TIME DEFAULT '13:00:00';

    DECLARE v_BEGIN_REST_TIME TIME;
    DECLARE v_END_REST_TIME TIME;
    DECLARE v_BEGIN_WORK_TIME TIME;
    DECLARE v_END_WORK_TIME TIME;

    DECLARE v_NEXT_BEGIN_DT DATETIME;
    DECLARE v_TODAY VARCHAR(10);

    DECLARE v_BEGIN_DT DATETIME;
    DECLARE v_END_DT DATETIME;
    DECLARE v_BEGIN_TIME TIME;
    DECLARE v_END_TIME TIME;

    DECLARE v_TYPE CHAR(1);
    DECLARE v_SPECIAL_BEGIN_DT DATETIME;
    DECLARE v_SPECIAL_END_DT DATETIME;

    DECLARE v_DIFF INT DEFAULT 0;
    DECLARE v_WORK_TIME INT DEFAULT 0;

    IF p_INIT_BEGIN_DT >= p_INIT_END_DT THEN
        RETURN 0;
    END IF;

    SET v_BEGIN_DT = p_INIT_BEGIN_DT;

    WHILE v_BEGIN_DT < p_INIT_END_DT
        DO
            -- 初始化变量
            SET v_BEGIN_REST_TIME = v_DEFAULT_BEGIN_REST_TIME;
            SET v_END_REST_TIME = v_DEFAULT_END_REST_TIME;
            SET v_BEGIN_WORK_TIME = v_DEFAULT_BEGIN_WORK_TIME;
            SET v_END_WORK_TIME = v_DEFAULT_END_WORK_TIME;

            SET v_SPECIAL_BEGIN_DT = NULL;
            SET v_SPECIAL_END_DT = NULL;
            SET v_TODAY = DATE_FORMAT(v_BEGIN_DT, '%Y-%m-%d');

            -- v_TYPE: '0' - 放假；'1' - 上班
            SET v_TYPE = IF(DATE_FORMAT(v_BEGIN_DT, '%w') IN (6, 0), '0', '1');

            -- 设置下一天的开始日期时间
            SET v_NEXT_BEGIN_DT = DATE_ADD(CONCAT(v_TODAY, ' 00:00:00'), INTERVAL 1 DAY);

            -- 设置当天的结束日期时间
            SET v_END_DT = IF(v_NEXT_BEGIN_DT <= p_INIT_END_DT, CONCAT(v_TODAY, ' 23:59:59'), p_INIT_END_DT);

            -- 设置当天的时间范围
            SET v_BEGIN_TIME = v_BEGIN_DT;
            SET v_END_TIME = v_END_DT;

            -- 获取节假日调休等特殊日期
            SELECT `CLS`
                  ,`BEGIN_DT`
                  ,`END_DT`
              INTO v_TYPE
                  ,v_SPECIAL_BEGIN_DT
                  ,v_SPECIAL_END_DT
              FROM `T_COMPANY_CALENDAR`
             WHERE `STATUS` = '1'
                   AND `CLS` IN ('0', '1')
                   AND v_BEGIN_DT < `END_DT`
                   AND v_END_DT > `BEGIN_DT`
            ORDER BY `ID` DESC
            LIMIT 1;

            -- 赋值上班时间
            IF v_TYPE = '0' THEN
                SET v_BEGIN_REST_TIME = v_DEFAULT_BEGIN_WORK_TIME;
                SET v_END_REST_TIME = v_DEFAULT_END_WORK_TIME;

                -- 如果是特殊放假，则修改午休时间来处理
                IF v_SPECIAL_BEGIN_DT IS NOT NULL AND v_SPECIAL_END_DT IS NOT NULL THEN
                    IF v_SPECIAL_BEGIN_DT > v_BEGIN_DT THEN
                        SET v_BEGIN_REST_TIME = v_SPECIAL_BEGIN_DT;
                    END IF;

                    IF v_SPECIAL_END_DT < v_END_DT THEN
                        SET v_END_REST_TIME = v_SPECIAL_END_DT;
                    END IF;
                ELSE
                    -- 普通放假时设置特殊的工作时间
                    SET v_BEGIN_WORK_TIME = '00:00:00';
                    SET v_END_WORK_TIME = '00:00:00';
                END IF;
            ELSE
                IF v_SPECIAL_BEGIN_DT IS NOT NULL AND v_SPECIAL_END_DT IS NOT NULL THEN
                    IF v_SPECIAL_BEGIN_DT > v_BEGIN_DT THEN
                        SET v_BEGIN_WORK_TIME = v_SPECIAL_BEGIN_DT;
                    END IF;

                    IF v_SPECIAL_END_DT < v_END_DT THEN
                        SET v_END_WORK_TIME = v_SPECIAL_END_DT;
                    END IF;
                END IF;
            END IF;

            -- 计算时间范围内的工作时间
            SET v_DIFF = `FN_CALC_DT_RANGE_DIFF`(v_BEGIN_TIME, v_END_TIME, v_BEGIN_WORK_TIME, v_END_WORK_TIME, 1);
            SET v_WORK_TIME = v_WORK_TIME + v_DIFF;

            -- 去除午休时间
            SET v_DIFF = `FN_CALC_DT_RANGE_DIFF`(v_BEGIN_WORK_TIME, v_END_WORK_TIME, v_BEGIN_REST_TIME, v_END_REST_TIME, 1);

            IF v_DIFF > 0 THEN
                SET v_DIFF = `FN_CALC_DT_RANGE_DIFF`(v_BEGIN_TIME, v_END_TIME, v_BEGIN_REST_TIME, v_END_REST_TIME, 1);
                SET v_WORK_TIME = v_WORK_TIME - v_DIFF;
            END IF;

            -- 设置下一个开始时间
            SET v_BEGIN_DT = v_NEXT_BEGIN_DT;
        END WHILE;

    RETURN IF(p_IS_WORK = 1, v_WORK_TIME, TIMESTAMPDIFF(MINUTE, p_INIT_BEGIN_DT, p_INIT_END_DT) - v_WORK_TIME);
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 去除字符串前后指定字符串
-- ============================================================
CREATE FUNCTION `FN_TRIM`(
     p_TEXT TEXT
    ,p_STR VARCHAR(128)
)
    RETURNS TEXT
BEGIN
    DECLARE v_TEXT TEXT DEFAULT p_TEXT;

    IF v_TEXT IS NOT NULL THEN
        SET v_TEXT = TRIM(v_TEXT);

        WHILE LOCATE(p_STR, v_TEXT) = 1
            DO
                SET v_TEXT = SUBSTRING(v_TEXT, LENGTH(p_STR) + 1, LENGTH(v_TEXT));
            END WHILE;

        SET v_TEXT = REVERSE(v_TEXT);
        SET p_STR = REVERSE(p_STR);

        WHILE LOCATE(p_STR, v_TEXT) = 1
            DO
                SET v_TEXT = SUBSTRING(v_TEXT, LENGTH(p_STR) + 1, LENGTH(v_TEXT));
            END WHILE;

        SET v_TEXT = TRIM(REVERSE(v_TEXT));
    END IF;

    RETURN v_TEXT;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 推送消息
-- ============================================================
CREATE PROCEDURE `SP_PUSH_MSG`(
     IN p_TO VARCHAR(1024)
    ,IN p_CC VARCHAR(1024)
    ,IN p_TITLE VARCHAR(64)
    ,IN p_CONTENT TEXT
    ,IN p_FROM_USER VARCHAR(64)
    ,IN p_ATTACHMENTS TEXT
)
BEGIN
    DECLARE v_SEP CHAR(1) DEFAULT ',';
    DECLARE v_USERS VARCHAR(2000);

    IF p_TITLE IS NULL THEN
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定标题';
    END IF;

    IF p_CONTENT IS NULL THEN
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定内容';
    END IF;

    IF p_TO IS NOT NULL THEN
        SET p_TO = `FN_TRIM`(p_TO, ',');
        SET v_USERS = p_TO;
    ELSE
        SIGNAL SQLSTATE '66666'
            SET MESSAGE_TEXT = '未指定收信人';
    END IF;

    IF p_CC IS NOT NULL THEN
        SET p_CC = `FN_TRIM`(p_CC, ',');
        SET v_USERS = CONCAT(v_USERS, ' , ', p_CC);
    END IF;

    INSERT INTO `chat_usermail`(`by`, `me`, `to`, `cc`, `is_read`, `is_push`, `title`, `content`, `attachments`, `edt`)
    SELECT p_FROM_USER
          ,value
          ,p_TO
          ,p_CC
          ,0
          ,0
          ,p_TITLE
          ,p_CONTENT
          ,p_ATTACHMENTS
          ,CURRENT_TIMESTAMP
      FROM (
               SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(v_USERS, v_SEP, `NUM` + 1), v_SEP, -1)) AS value
                 FROM `T_SYSTEM_AUXILIARY`
                WHERE `NUM` <= FN_COUNT_STR(v_USERS, v_SEP)
                      AND `TYPE` = 'P'
           ) T
     WHERE value <> '';
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 日历事件提醒存储过程
-- ============================================================
CREATE PROCEDURE `SP_HANDLE_CALENDAR_EVENTS`()
BEGIN
    DECLARE v_ID INT;
    DECLARE v_INAME VARCHAR(8);
    DECLARE v_NAME VARCHAR(16);
    DECLARE v_TITLE VARCHAR(64);
    DECLARE v_CONTENT TEXT;
    DECLARE v_WARN_TIMES INT;
    DECLARE v_DONE INT DEFAULT 0;

    DECLARE cur_calendar_events CURSOR
        FOR SELECT `ID`
                  ,`I_NAME`
                  ,`NAME`
                   ,IFNULL(`WARN_TIMES`, 1)
              FROM `T_COMPANY_CALENDAR`
             WHERE `STATUS` = '1'
                   AND `CLS` = '3'
                   AND IFNULL(`WARN_TIMES`, 1) > 0
                   AND CAST(DATE_ADD(NOW(), INTERVAL IFNULL(`WARN_DAY`,0) DAY) AS DATE) BETWEEN CAST(`BEGIN_DT` AS DATE) AND CAST(`END_DT` AS DATE);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_DONE = 1;

    OPEN cur_calendar_events;
    posLoop:
    LOOP
        FETCH cur_calendar_events into v_ID,v_INAME,v_NAME,v_WARN_TIMES;

        IF v_DONE = 1 THEN
            LEAVE posLoop;
        END IF;

        SET v_WARN_TIMES = v_WARN_TIMES - 1;

        SET v_TITLE = CONCAT('日程提醒【', v_NAME, '】');

        IF v_WARN_TIMES > 0 THEN
            SET v_TITLE = CONCAT(v_TITLE, '，将继续提醒', v_WARN_TIMES, '天');
        ELSE
            SET v_TITLE = CONCAT(v_TITLE, '，以后将不再提醒，如需继续提醒，请重写修改提醒次数');
        END IF;

        SET v_CONTENT = CONCAT('<a href="/datacenter/calendar?id=', v_ID, '" target="_blank">详细内容，请点击查看</a>');

        CALL `SP_PUSH_MSG`(v_INAME, NULL, v_TITLE, v_CONTENT, 'system', '');

        UPDATE `T_COMPANY_CALENDAR` SET `WARN_TIMES` = v_WARN_TIMES WHERE `ID` = v_ID;
    END LOOP posLoop;
    CLOSE cur_calendar_events;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 通讯录更新触发器，生成工号、赋予菜单和数据权限
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_STAFF_U`
    BEFORE UPDATE
    ON `T_COMPANY_STAFF`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_GID INT DEFAULT NEW.GID;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;
    DECLARE v_UNAME VARCHAR(8) DEFAULT NEW.U_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_NAME VARCHAR(8);
    DECLARE v_STAFF_ID VARCHAR(8) DEFAULT IFNULL(NEW.STAFF_ID, '');
    DECLARE v_LEADERS VARCHAR(128) DEFAULT NEW.LEADERS;
    DECLARE v_FULL_NAME VARCHAR(32) DEFAULT NEW.FULL_NAME;
    DECLARE v_ROLES TEXT DEFAULT NEW.ROLES;
    DECLARE v_PASSWORD VARCHAR(128) DEFAULT 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=';
    DECLARE v_MSG TEXT;
    DECLARE v_SEP CHAR(1) DEFAULT ',';

    IF IFNULL(OLD.U_DT, '') <> IFNULL(NEW.U_DT, '') OR IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') OR
       IFNULL(OLD.STATUS, '') <> IFNULL(NEW.STATUS, '') THEN
        IF v_STATUS = '1' THEN
            -- 生成工号
            IF LENGTH(v_STAFF_ID) = 4 THEN
                SET v_STAFF_ID = CONCAT(v_GID, v_STAFF_ID);

                IF EXISTS(SELECT 1 FROM `T_COMPANY_STAFF` WHERE `STAFF_ID` = v_STAFF_ID) THEN
                    SET v_MSG = CONCAT('ID=', v_ID, '，生成的工号重复了，请更换编号后重试');
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = v_MSG;
                ELSE
                    SET NEW.STAFF_ID = v_STAFF_ID;
                END IF;
            END IF;

            IF LENGTH(v_STAFF_ID) <> 6 THEN
                SET v_MSG = CONCAT('ID=', v_ID, '，未指定工号');
                SIGNAL SQLSTATE '66666'
                    SET MESSAGE_TEXT = v_MSG;
            END IF;

            -- 更新账号
            IF EXISTS(SELECT 1 FROM `auth_user` WHERE `username` = v_STAFF_ID) THEN
                UPDATE `auth_user` SET `first_name` = v_FULL_NAME WHERE `username` = v_STAFF_ID;
            ELSE
                INSERT INTO `auth_user`(`password`, `is_superuser`, `username`, `first_name`, `last_name`, `email`, `is_staff`, `is_active`, `date_joined`)
                VALUES (v_PASSWORD, 0, v_STAFF_ID, v_FULL_NAME, '', '', 0, 1, CURRENT_TIMESTAMP);
            END IF;

            -- 更新关系
            IF OLD.STATUS = '0' OR IFNULL(OLD.LEADERS, '') <> IFNULL(NEW.LEADERS, '') THEN
                IF v_LEADERS IS NULL THEN
                    SET v_LEADERS = '';
                END IF;

                IF v_UNAME IS NOT NULL THEN
                    SET v_NAME = v_UNAME;
                ELSE
                    SET v_NAME = v_VNAME;
                END IF;

                -- 1. 更新
                UPDATE `T_COMPANY_STAFF_RELATION`
                   SET `STATUS` = IF(LOCATE(TRIM(`STAFF_ID_L`), v_LEADERS) = 0, '0', '1')
                      ,`U_NAME` = v_NAME
                      ,`U_DT`   = CURRENT_TIMESTAMP
                 WHERE `STAFF_ID` = v_STAFF_ID;

                -- 2. 新增
                INSERT INTO `T_COMPANY_STAFF_RELATION`(`I_NAME`, `STATUS`, `STAFF_ID`, `STAFF_ID_L`)
                SELECT v_NAME, '1', v_STAFF_ID, value
                FROM (
                         SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(v_LEADERS, v_SEP, `NUM` + 1), v_SEP, -1)) AS value
                           FROM `T_SYSTEM_AUXILIARY`
                          WHERE `NUM` <= FN_COUNT_STR(v_LEADERS, v_SEP)
                                AND `TYPE` = 'P'
                     ) T
                WHERE value <> ''
                      AND value NOT IN (
                          SELECT `STAFF_ID_L` FROM `T_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_STAFF_ID
                      );
            END IF;

            -- 更新权限
            IF OLD.STATUS = '0' OR IFNULL(OLD.ROLES, '') <> IFNULL(NEW.ROLES, '') THEN
                IF v_ROLES IS NULL THEN
                    SET v_ROLES = '';
                END IF;

                CREATE TEMPORARY TABLE tmp_ids
                (
                    `id` INT
                );

                INSERT INTO tmp_ids(`id`)
                SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(v_ROLES, v_SEP, `NUM` + 1), v_SEP, -1)) AS value
                  FROM `T_SYSTEM_AUXILIARY`
                 WHERE `NUM` <= FN_COUNT_STR(v_ROLES, v_SEP)
                       AND `TYPE` = 'P';

                -- 1. 更新
                UPDATE `base_userrole` a, tmp_ids b
                   SET `enable` = IF(b.`id` IS NOT NULL, 1, 0)
                 WHERE a.`role_id` = b.`id`
                       AND a.`user` = v_STAFF_ID;

                -- 2. 新增
                INSERT INTO `base_userrole`(`user`, `enable`, `edt`, `udt`, `role_id`)
                SELECT v_STAFF_ID, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, `id`
                  FROM tmp_ids
                 WHERE `id` NOT IN (SELECT `role_id` FROM `base_userrole` WHERE `user` = v_STAFF_ID);
            END IF;
        END IF;

        IF v_STATUS = '2' THEN
            UPDATE `auth_user` SET `is_active` = 0 WHERE `username` = v_STAFF_ID;
        END IF;
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 系统反馈
-- ============================================================
CREATE TABLE `T_SYSTEM_FEEDBACK`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`CLS` VARCHAR(32)
    ,`TITLE` VARCHAR(1024)
    ,`CONTENT` TEXT
    ,CONSTRAINT `PK_T_SYSTEM_FEEDBACK` PRIMARY KEY (ID)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_STATUS`(`STATUS`)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_I_NAME`(`I_NAME`)
    ,INDEX `IX_T_SYSTEM_FEEDBACK_I_DT`(`I_DT`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 文件管理
-- ============================================================
CREATE TABLE `T_COMPANY_FILES`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`NAME` NVARCHAR(256)
	,`PATH` NVARCHAR(2000)
	,`SIZE` INT
	,`ADT` DATETIME
	,`MDT` DATETIME
	,`CDT` DATETIME
    ,CONSTRAINT `PK_T_COMPANY_FILES` PRIMARY KEY (ID)
	,INDEX `IX_T_COMPANY_FILES_GID`(`GID`)
    ,INDEX `IX_T_COMPANY_FILES_STATUS`(`STATUS`)
    ,INDEX `IX_T_COMPANY_FILES_NAME`(`NAME`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 事件管理
-- ============================================================
CREATE TABLE `T_COMPANY_EVENT`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`EVENT` VARCHAR(128)
    ,`ROLES` TEXT
    ,`USERS` TEXT
    ,`REMARK` TEXT
    ,CONSTRAINT `PK_T_COMPANY_EVENT` PRIMARY KEY (ID)
	,INDEX `IX_T_COMPANY_EVENT_GID`(`GID`)
    ,INDEX `IX_T_COMPANY_EVENT_STATUS`(`STATUS`)
    ,INDEX `IX_T_COMPANY_EVENT_I_NAME`(`I_NAME`)
    ,INDEX `IX_T_COMPANY_EVENT_I_DT`(`I_DT`)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 请假条
-- ============================================================
CREATE TABLE `T_COMPANY_LEAVE_INFO`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`CLS` VARCHAR(4)
    ,`BEGIN_DT` DATETIME
	,`END_DT` DATETIME
	,`TOTAL` INT
	,`REASON` VARCHAR(1024)
	,`ATTACHMENTS` TEXT
	,`REMARK` TEXT
	,`SQ` VARCHAR(32)
	,`ZG` VARCHAR(32)
    ,CONSTRAINT `PK_T_COMPANY_LEAVE_INFO` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 加班单
-- ============================================================
CREATE TABLE `T_COMPANY_OVERTIME_INFO`
(
     `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID`    INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1)      NOT NULL DEFAULT '0'
    ,`I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT`   DATETIME
    ,`V_DT`   DATETIME
    ,`I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`BEGIN_DT` DATETIME
	,`END_DT` DATETIME
	,`TOTAL` INT
	,`REASON` VARCHAR(1024)
	,`REMARK` TEXT
	,`SQ` VARCHAR(32)
	,`ZG` VARCHAR(32)
    ,CONSTRAINT `PK_T_COMPANY_OVERTIME_INFO` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 调休单
-- ============================================================
CREATE TABLE `T_COMPANY_DAYOFF_INFO`
(
     `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID`    INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1)      NOT NULL DEFAULT '0'
    ,`I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT`   DATETIME
    ,`V_DT`   DATETIME
    ,`I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`BEGIN_DT` DATETIME
	,`END_DT` DATETIME
	,`TOTAL` INT
	,`REMAIN` INT
	,`REASON` VARCHAR(1024)
	,`REMARK` TEXT
	,`SQ` VARCHAR(32)
	,`ZG` VARCHAR(32)
    ,CONSTRAINT `PK_T_COMPANY_DAYOFF_INFO` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 漏打卡
-- ============================================================
CREATE TABLE `T_COMPANY_FORGET_PUNCH`
(
     `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID`    INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1)      NOT NULL DEFAULT '0'
    ,`I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT`   DATETIME
    ,`V_DT`   DATETIME
    ,`I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`ED` DATE
	,`CLS` VARCHAR(16)
	,`REASON` VARCHAR(1024)
	,`REMARK` TEXT
	,`SQ` VARCHAR(32)
	,`ZG` VARCHAR(32)
    ,CONSTRAINT `PK_T_COMPANY_FORGET_PUNCH` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 出门条
-- ============================================================
CREATE TABLE `T_COMPANY_OUT_SIGN`
(
     `ID`     INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID`    INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1)      NOT NULL DEFAULT '0'
    ,`I_DT`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT`   DATETIME
    ,`V_DT`   DATETIME
    ,`I_NAME` VARCHAR(8)   NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`EDT` DATETIME
	,`REASON` VARCHAR(1024)
	,`REMARK` TEXT
	,`SQ` VARCHAR(32)
	,`ZG` VARCHAR(32)
    ,CONSTRAINT `PK_T_COMPANY_OUT_SIGN` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 计算请假工时以及审核验证
--               验证策略：大于三天总经理审核，否则领导审核
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_LEAVE_INFO_U`
    BEFORE UPDATE
    ON `T_COMPANY_LEAVE_INFO`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_INAME VARCHAR(8) DEFAULT NEW.I_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;
    DECLARE v_BEGIN_DT DATETIME DEFAULT NEW.BEGIN_DT;
    DECLARE v_END_DT DATETIME DEFAULT NEW.END_DT;
    DECLARE v_TOTAL INT DEFAULT NEW.TOTAL;

    DECLARE v_PRE_STATUS CHAR(1) DEFAULT OLD.STATUS;
    DECLARE v_NEXT_STATUS CHAR(1);
    DECLARE v_FULLNAME VARCHAR(16);

    -- 超过三天总经理审核
    DECLARE v_LIMIT INT DEFAULT 3 * 8 * 60;


    -- 待办事项相关变量
    DECLARE v_STAFF_ID VARCHAR(8);
    DECLARE v_RANK INT;

    DECLARE v_TAG VARCHAR(16) DEFAULT '请假条待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个请假条待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/qjt?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        IF v_STATUS = 'a' THEN
            SET v_FULLNAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

            IF v_PRE_STATUS = '0' THEN
                SET v_TOTAL = `FN_CALC_WORK_MINUTE`(v_BEGIN_DT, v_END_DT, 1);
                SET v_STAFF_ID = v_INAME;
                SET v_RANK = IF(v_TOTAL >= v_LIMIT, 2, 3);
                SET v_NEXT_STATUS = '1';
            ELSE
                -- 设置权限偏移值
                SET v_RANK = (SELECT `RANK` FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_INAME AND `STAFF_ID_L` = v_VNAME);

                IF v_TOTAL >= v_LIMIT AND IFNULL(v_RANK, 100) > 2 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '3天以内部门主管审核，超过3天需总经理审批';
                END IF;

                IF IFNULL(v_RANK, 100) > 3 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '需领导审核';
                END IF;

                SET v_STAFF_ID = NULL;
                SET v_RANK = 100;
                SET v_NEXT_STATUS = '2';
            END IF;

            SET NEW.STATUS = v_NEXT_STATUS;
            SET NEW.SQ = IF(v_NEXT_STATUS = '1', v_FULLNAME, NEW.SQ);
            SET NEW.ZG = IF(v_NEXT_STATUS = '2', v_FULLNAME, NEW.ZG);
            SET NEW.TOTAL = v_TOTAL;
        END IF;

        -- 设置URL和CONTENT，用于更新待办事项
        SET v_CONTENT = CONCAT(v_INAME, '(', v_FULLNAME, ')', v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);
        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(NULL, NULL, v_STAFF_ID, v_RANK, v_TAG, v_CONTENT, v_URL, v_VNAME);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 计算加班工时以及审核验证
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_OVERTIME_INFO_U`
    BEFORE UPDATE
    ON `T_COMPANY_OVERTIME_INFO`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_INAME VARCHAR(8) DEFAULT NEW.I_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;
    DECLARE v_BEGIN_DT DATETIME DEFAULT NEW.BEGIN_DT;
    DECLARE v_END_DT DATETIME DEFAULT NEW.END_DT;
    DECLARE v_TOTAL INT DEFAULT NEW.TOTAL;

    DECLARE v_PRE_STATUS CHAR(1) DEFAULT OLD.STATUS;
    DECLARE v_NEXT_STATUS CHAR(1);
    DECLARE v_FULLNAME VARCHAR(16);

    -- 待办事项相关变量
    DECLARE v_STAFF_ID VARCHAR(8);
    DECLARE v_RANK INT;

    DECLARE v_TAG VARCHAR(16) DEFAULT '加班条待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个加班条待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/jbt?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        IF v_STATUS = 'a' THEN
            SET v_FULLNAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

            IF v_PRE_STATUS = '0' THEN
                SET v_TOTAL = `FN_CALC_WORK_MINUTE`(v_BEGIN_DT, v_END_DT, 0);
                IF v_TOTAL <=0 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '时间范围错误，计算出的加班时长小于1分钟';
                END IF;

                SET v_STAFF_ID = v_INAME;
                SET v_RANK = 3;
                SET v_NEXT_STATUS = '1';
            ELSE
                -- 设置权限偏移值
                SET v_RANK = (SELECT `RANK` FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_INAME AND `STAFF_ID_L` = v_VNAME);

                IF IFNULL(v_RANK, 100) > 3 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '需领导审核';
                END IF;

                SET v_STAFF_ID = NULL;
                SET v_RANK = 100;
                SET v_NEXT_STATUS = '2';
            END IF;

            SET NEW.STATUS = v_NEXT_STATUS;
            SET NEW.SQ = IF(v_NEXT_STATUS = '1', v_FULLNAME, NEW.SQ);
            SET NEW.ZG = IF(v_NEXT_STATUS = '2', v_FULLNAME, NEW.ZG);
            SET NEW.TOTAL = v_TOTAL;
        END IF;

        -- 设置URL和CONTENT，用于更新待办事项
        SET v_CONTENT = CONCAT(v_INAME, '(', v_FULLNAME, ')', v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);
        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(NULL, NULL, v_STAFF_ID, v_RANK, v_TAG, v_CONTENT, v_URL, v_VNAME);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 计算调休工时以及审核验证
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_DAYOFF_INFO_U`
    BEFORE UPDATE
    ON `T_COMPANY_DAYOFF_INFO`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_INAME VARCHAR(8) DEFAULT NEW.I_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;
    DECLARE v_BEGIN_DT DATETIME DEFAULT NEW.BEGIN_DT;
    DECLARE v_END_DT DATETIME DEFAULT NEW.END_DT;
    DECLARE v_TOTAL INT DEFAULT NEW.TOTAL;
    DECLARE v_REMAIN INT DEFAULT NEW.REMAIN;

    -- 超过三天总经理审核
    DECLARE v_LIMIT INT DEFAULT 3 * 8 * 60;

    DECLARE v_PRE_STATUS CHAR(1) DEFAULT OLD.STATUS;
    DECLARE v_NEXT_STATUS CHAR(1);
    DECLARE v_FULLNAME VARCHAR(16);

    -- 待办事项相关变量
    DECLARE v_STAFF_ID VARCHAR(8);
    DECLARE v_RANK INT;

    DECLARE v_TAG VARCHAR(16) DEFAULT '调休单待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个调休单待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/txd?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        IF v_STATUS = 'a' THEN
            SET v_FULLNAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

            SET v_REMAIN = (
                    (SELECT IFNULL(SUM(TOTAL), 0)
                     FROM `T_COMPANY_OVERTIME_INFO`
                     WHERE `I_NAME` = v_INAME
                       AND `STATUS` = '2') -
                    (SELECT IFNULL(SUM(TOTAL), 0)
                     FROM `T_COMPANY_DAYOFF_INFO`
                     WHERE `I_NAME` = v_INAME
                       AND `STATUS` = '2')
                );

            IF v_REMAIN <= 0 THEN
                SIGNAL SQLSTATE '66666'
                    SET MESSAGE_TEXT = '剩余调休不足';
            END IF;

            IF v_PRE_STATUS = '0' THEN
                SET v_TOTAL = `FN_CALC_WORK_MINUTE`(v_BEGIN_DT, v_END_DT, 1);
                IF v_TOTAL <= 0 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '时间范围错误，计算出的调休时长小于1分钟';
                END IF;

                SET v_STAFF_ID = v_INAME;
                SET v_RANK = IF(v_TOTAL >= v_LIMIT, 2, 3);
                SET v_NEXT_STATUS = '1';
            ELSE
                -- 设置权限偏移值
                SET v_RANK = (SELECT `RANK` FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_INAME AND `STAFF_ID_L` = v_VNAME);

                IF v_TOTAL >= v_LIMIT AND IFNULL(v_RANK, 100) > 2 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '3天以内部门主管审核，超过3天需总经理审批';
                END IF;

                IF IFNULL(v_RANK, 100) > 3 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '需领导审核';
                END IF;

                SET v_STAFF_ID = NULL;
                SET v_RANK = 100;
                SET v_NEXT_STATUS = '2';
            END IF;

            SET NEW.STATUS = v_NEXT_STATUS;
            SET NEW.SQ = IF(v_NEXT_STATUS = '1', v_FULLNAME, NEW.SQ);
            SET NEW.ZG = IF(v_NEXT_STATUS = '2', v_FULLNAME, NEW.ZG);
            SET NEW.TOTAL = v_TOTAL;
            SET NEW.REMAIN = v_REMAIN;
        END IF;

        -- 设置URL和CONTENT，用于更新待办事项
        SET v_CONTENT = CONCAT(v_INAME, '(', v_FULLNAME, ')', v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);
        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(NULL, NULL, v_STAFF_ID, v_RANK, v_TAG, v_CONTENT, v_URL, v_VNAME);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 漏打卡审核验证
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_FORGET_PUNCH_U`
    BEFORE UPDATE
    ON `T_COMPANY_FORGET_PUNCH`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_INAME VARCHAR(8) DEFAULT NEW.I_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;

    DECLARE v_PRE_STATUS CHAR(1) DEFAULT OLD.STATUS;
    DECLARE v_NEXT_STATUS CHAR(1);
    DECLARE v_FULLNAME VARCHAR(16);

    -- 待办事项相关变量
    DECLARE v_STAFF_ID VARCHAR(8);
    DECLARE v_RANK INT;

    DECLARE v_TAG VARCHAR(16) DEFAULT '漏打卡待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个漏打卡待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/ldk?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        IF v_STATUS = 'a' THEN
            SET v_FULLNAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

            IF v_PRE_STATUS = '0' THEN
                SET v_STAFF_ID = v_INAME;
                SET v_RANK = 3;
                SET v_NEXT_STATUS = '1';
            ELSE
                -- 设置权限偏移值
                SET v_RANK = (SELECT `RANK` FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_INAME AND `STAFF_ID_L` = v_VNAME);

                IF IFNULL(v_RANK, 100) > 3 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '需领导审核';
                END IF;

                SET v_STAFF_ID = NULL;
                SET v_RANK = 100;
                SET v_NEXT_STATUS = '2';
            END IF;

            SET NEW.STATUS = v_NEXT_STATUS;
            SET NEW.SQ = IF(v_NEXT_STATUS = '1', v_FULLNAME, NEW.SQ);
            SET NEW.ZG = IF(v_NEXT_STATUS = '2', v_FULLNAME, NEW.ZG);
        END IF;

        -- 设置URL和CONTENT，用于更新待办事项
        SET v_CONTENT = CONCAT(v_INAME, '(', v_FULLNAME, ')', v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);
        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(NULL, NULL, v_STAFF_ID, v_RANK, v_TAG, v_CONTENT, v_URL, v_VNAME);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 漏打卡审核验证
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_OUT_SIGN_U`
    BEFORE UPDATE
    ON `T_COMPANY_OUT_SIGN`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_INAME VARCHAR(8) DEFAULT NEW.I_NAME;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;

    DECLARE v_PRE_STATUS CHAR(1) DEFAULT OLD.STATUS;
    DECLARE v_NEXT_STATUS CHAR(1);
    DECLARE v_FULLNAME VARCHAR(16);

    -- 待办事项相关变量
    DECLARE v_STAFF_ID VARCHAR(8);
    DECLARE v_RANK INT;

    DECLARE v_TAG VARCHAR(16) DEFAULT '出门条待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个出门条待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/cmt?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        IF v_STATUS = 'a' THEN
            SET v_FULLNAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

            IF v_PRE_STATUS = '0' THEN
                SET v_STAFF_ID = v_INAME;
                SET v_RANK = 3;
                SET v_NEXT_STATUS = '1';
            ELSE
                -- 设置权限偏移值
                SET v_RANK = (SELECT `RANK` FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID` = v_INAME AND `STAFF_ID_L` = v_VNAME);

                IF IFNULL(v_RANK, 100) > 3 THEN
                    SIGNAL SQLSTATE '66666'
                        SET MESSAGE_TEXT = '需领导审核';
                END IF;

                SET v_STAFF_ID = NULL;
                SET v_RANK = 100;
                SET v_NEXT_STATUS = '2';
            END IF;

            SET NEW.STATUS = v_NEXT_STATUS;
            SET NEW.SQ = IF(v_NEXT_STATUS = '1', v_FULLNAME, NEW.SQ);
            SET NEW.ZG = IF(v_NEXT_STATUS = '2', v_FULLNAME, NEW.ZG);
        END IF;

        -- 设置URL和CONTENT，用于更新待办事项
        SET v_CONTENT = CONCAT(v_INAME, '(', v_FULLNAME, ')', v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);
        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(NULL, NULL, v_STAFF_ID, v_RANK, v_TAG, v_CONTENT, v_URL, v_VNAME);
    END IF;
END;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工档案-信息表
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF_INFO`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`BH` INT
	,`GH` VARCHAR(8)
	,`GS` VARCHAR(128)
	,`BM` VARCHAR(128)
	,`XM` VARCHAR(32)
	,`SJHM` VARCHAR(128)
	,`SFZH` CHAR(18)
	,`YHKH` VARCHAR(128)
	,`GJJZH` VARCHAR(12)
	,`JZGW` VARCHAR(128)
	,`RZSJ` DATE
	,`HTYXQ` DATE
	,`ZZ` VARCHAR(32)
	,`JG` VARCHAR(32)
	,`HJ` VARCHAR(32)
	,`HY` CHAR(2)
	,`ZN` INT
	,`HJDZ` VARCHAR(256)
	,`HZDZ` VARCHAR(256)
	,`ZS` VARCHAR(256)
	,`BZ` TEXT
	,`SX` INT
    ,CONSTRAINT `PK_T_COMPANY_STAFF_INFO` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工档案-信息表查询视图
-- ============================================================
CREATE VIEW `V_T_COMPANY_STAFF_INFO`
AS
SELECT `ID`
      ,`GID`
      ,`STATUS`
      ,`I_NAME`
      ,`I_DT`
      ,`U_NAME`
      ,`U_DT`
      ,`V_NAME`
      ,`V_DT`
      ,`BH`
      ,`GH`
      ,`GS`
      ,`BM`
      ,`XM`
      ,`SJHM`
      ,`SFZH`
      ,`YHKH`
      ,`GJJZH`
      ,`JZGW`
      ,`RZSJ`
      ,`HTYXQ`
      ,(IF(CAST(SUBSTRING(`SFZH`, 17,1) AS UNSIGNED)%2 = 1, '男', '女')) AS `XB`
      ,CAST(TIMESTAMPDIFF(MONTH , `RZSJ`, CURRENT_TIMESTAMP)/12.0 AS DECIMAL(3,1)) AS `GL`
      ,CAST(TIMESTAMPDIFF(MONTH , SUBSTRING(`SFZH`,7,8), CURRENT_TIMESTAMP)/12.0 AS DECIMAL(3,1)) AS `NL`
      ,`ZZ`
      ,`JG`
      ,`HJ`
      ,`HY`
      ,`ZN`
      ,`HJDZ`
      ,`HZDZ`
      ,`ZS`
      ,`BZ`
  FROM `T_COMPANY_STAFF_INFO`;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工档案-简历表
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF_INFO_JL`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`FK` INT NOT NULL
	,`RZSJ` VARCHAR(32)
	,`GS` VARCHAR(128)
	,`ZW` VARCHAR(128)
    ,CONSTRAINT `PK_T_COMPANY_STAFF_INFO_JL` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2022-04-21
-- Description : 员工档案-学历表
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF_INFO_XL`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`FK` INT NOT NULL
	,`YX` VARCHAR(128)
	,`ZY` VARCHAR(128)
	,`XZ` VARCHAR(32)
	,`XL` VARCHAR(32)
	,`FJ` TEXT
    ,CONSTRAINT `PK_T_COMPANY_STAFF_INFO_XL` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工档案-离职表
-- ============================================================
CREATE TABLE `T_COMPANY_STAFF_INFO_LZ`(
     `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT
    ,`GID` INT UNSIGNED NOT NULL DEFAULT 0
    ,`STATUS` CHAR(1) NOT NULL DEFAULT '0'
    ,`I_DT` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,`U_DT` DATETIME
    ,`V_DT` DATETIME
    ,`I_NAME` VARCHAR(8) NOT NULL DEFAULT 'system'
    ,`U_NAME` VARCHAR(8)
    ,`V_NAME` VARCHAR(8)
    ,`FK` INT NOT NULL
	,`ZG` VARCHAR(16)
	,`BM` VARCHAR(32)
	,`ZW` VARCHAR(32)
	,`CZSJ` DATE
	,`CZYY` TEXT
	,`ZGYJ` TEXT
	,`RSYJ` TEXT
	,`JLYJ` TEXT
	,`YJQD` TEXT
	,`SJZG` VARCHAR(16)
	,`RSZG` VARCHAR(16)
	,`ZJL` VARCHAR(16)
	,`DF` TEXT
	,`TO` VARCHAR(256)
	,`CC` VARCHAR(256)
    ,CONSTRAINT `PK_T_COMPANY_STAFF_INFO_LZ` PRIMARY KEY (ID)
);

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2022-04-21
-- Description : 员工档案-离职表查询视图
-- ============================================================
CREATE VIEW `V_T_COMPANY_STAFF_INFO_LZ`
AS
SELECT a.`ID`
      ,a.`GID`
      ,a.`STATUS`
      ,a.`I_DT`
      ,a.`U_DT`
      ,a.`V_DT`
      ,a.`I_NAME`
      ,a.`U_NAME`
      ,a.`V_NAME`
      ,a.`FK`
      ,b.`XM`
      ,b.`RZSJ`
      ,a.`BM`
      ,a.`ZW`
      ,a.`CZSJ`
      ,a.`ZG`
      ,a.`CZYY`
      ,a.`ZGYJ`
      ,a.`RSYJ`
      ,a.`JLYJ`
      ,a.`YJQD`
      ,a.`SJZG`
      ,a.`RSZG`
      ,a.`ZJL`
      ,a.`TO`
      ,a.`CC`
      ,a.`DF`
  FROM `T_COMPANY_STAFF_INFO_LZ` a
       INNER JOIN
       `T_COMPANY_STAFF_INFO` b
           ON a.`FK` = b.`ID`;

;;;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 员工档案-离职处理
-- ============================================================
CREATE TRIGGER `TR_T_COMPANY_STAFF_INFO_LZ_U`
    BEFORE UPDATE
    ON `T_COMPANY_STAFF_INFO_LZ`
    FOR EACH ROW
BEGIN
    DECLARE v_ID INT DEFAULT NEW.ID;
    DECLARE v_VDT DATETIME DEFAULT NEW.V_DT;
    DECLARE v_VNAME VARCHAR(8) DEFAULT NEW.V_NAME;
    DECLARE v_STATUS CHAR(1) DEFAULT NEW.STATUS;
    DECLARE v_FK INT DEFAULT NEW.FK;
    DECLARE v_TO VARCHAR(256) DEFAULT NEW.`TO`;
    DECLARE v_CC VARCHAR(256) DEFAULT NEW.CC;
    DECLARE v_DF VARCHAR(1024) DEFAULT NEW.DF;

    DECLARE v_SQ VARCHAR(16);
    DECLARE v_NAME VARCHAR(16);

    -- 待办事项相关变量
    DECLARE v_TAG VARCHAR(16) DEFAULT '离职单待处理';
    DECLARE v_CONTENT VARCHAR(1024);
    DECLARE v_CONTENT_DEFAULT VARCHAR(1024) DEFAULT '有一个离职单待处理';
    DECLARE v_URL VARCHAR(1024);
    DECLARE v_URL_DEFAULT VARCHAR(1024) DEFAULT '/datacenter/lzb?id=';

    IF IFNULL(OLD.V_DT, '') <> IFNULL(NEW.V_DT, '') THEN
        -- 获取申请人姓名，并生成待办事项
        SET v_SQ = (SELECT `XM` FROM `T_COMPANY_STAFF_INFO` WHERE `ID` = v_FK);

        SET v_CONTENT = CONCAT(v_SQ, v_CONTENT_DEFAULT);
        SET v_URL = CONCAT(v_URL_DEFAULT, v_ID);

        CALL `SP_ADD_TODO_LIST_FOR_TRIGGER`(v_TO, NULL, NULL, NULL, v_TAG, v_CONTENT, v_URL, v_VNAME);

        SET v_NAME = `FN_GET_USERNAME_BY_STAFF_ID`(v_VNAME);

        IF v_TO IS NOT NULL THEN
            -- 姓名|工号|时间>666666,888888;...
            SET v_DF = CONCAT(IFNULL(v_DF, ''), v_NAME, '|', v_VNAME, '|', v_VDT, '>', v_TO);

            IF v_CC IS NOT NULL THEN
                SET v_DF = CONCAT(v_DF, ' , ', v_CC);
            END IF;

            SET v_DF = CONCAT(v_DF, ';');
        ELSE
            SET v_DF = NULL;
        END IF;

        SET NEW.SJZG = CASE v_STATUS WHEN '0' THEN NULL WHEN '2' THEN v_NAME ELSE NEW.SJZG END;
        SET NEW.RSZG = CASE v_STATUS WHEN '0' THEN NULL WHEN '3' THEN v_NAME ELSE NEW.RSZG END;
        SET NEW.ZJL = CASE v_STATUS WHEN '0' THEN NULL WHEN '4' THEN v_NAME ELSE NEW.ZJL END;
        SET NEW.ZGYJ = IF(v_STATUS = '0', NULL, NEW.ZGYJ);
        SET NEW.RSYJ = IF(v_STATUS = '0', NULL, NEW.RSYJ);
        SET NEW.JLYJ = IF(v_STATUS = '0', NULL, NEW.JLYJ);
        SET NEW.TO = NULL;
        SET NEW.CC = NULL;
        SET NEW.DF = v_DF;

        IF v_STATUS = '4' THEN
            UPDATE `T_COMPANY_STAFF_INFO` SET `STATUS` = '1' WHERE `ID` = v_FK;
            UPDATE `T_COMPANY_STAFF` SET `STATUS` = '2' WHERE `STAFF_ID` IN (SELECT `GH` FROM `T_COMPANY_STAFF_INFO` WHERE `ID` = v_FK);
        END IF;
    END IF;
END;

;;;

DELIMITER ;

-- ============================================================
-- Author      : Dawn
-- Create date : 2021-04-21
-- Description : 基础数据
-- Modify [1]  : Dawn, 2022-04-01, 重新生成
-- ============================================================
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (1, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', '2022-05-14 10:23:42.751621', 1, 'admin', '管理员', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36', '', 1, 1, '2022-05-06 22:15:00');
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (2, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', null, 0, 'system', '系统账号', '', '.', 0, 1, '2022-05-06 07:54:08');
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (3, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', null, 0, '100001', 'Dawn', '', '*', 0, 1, '2022-05-13 17:47:26');
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (4, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', null, 0, '100002', '陈一', '', '', 0, 1, '2022-05-13 17:56:14');
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (5, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', '2022-05-14 19:56:32.781788', 0, '100003', '陈二', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36', '', 0, 1, '2022-05-13 17:56:14');
INSERT INTO aioa.auth_user (id, password, last_login, is_superuser, username, first_name, last_name, email, is_staff, is_active, date_joined) VALUES (6, 'pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU=', '2022-05-14 20:40:25.485551', 0, '100004', '陈三', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.54 Safari/537.36', '*', 0, 1, '2022-05-13 18:03:48');

INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (1, '默认配置', '{}', '1', null, '2022-05-06 07:54:08', '2022-05-06 23:15:18.598687');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (2, '默认权限', '{}', '2', null, '2022-05-06 07:54:08', '2022-05-06 23:15:18.597685');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (3, '默认流程', '{}', '3', null, '2022-05-06 07:54:08', '2022-05-06 23:15:18.594677');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (4, '配置映射', '{
  "message": 5,
  "textmap": 6
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.635070');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (5, '消息映射', '{
  "测试": [
    "测试",
    "Test"
  ]
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.631049');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (6, '文本映射', '{
  "company": {
    "10": "xx集团",
    "20": "xx科技"
  },
  "abbr": {
    "xx集团": "上海xx集团股份有限公司",
    "xx科技": "上海xx科技股份有限公司"
  },
  "full": {
    "上海xx集团股份有限公司": "xx集团",
    "上海xx科技股份有限公司": "xx科技"
  }
}', '4', '', '2022-05-06 07:54:08', '2022-05-10 16:19:20.634752');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (7, '查看权限', '{
  "e_list_status": false,
  "v_list_status": false
}', '2', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.622025');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (8, '查看&编辑', '{
  "v_list_status": false
}', '2', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.619017');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (9, '查看&审核', '{
  "e_list_status": false
}', '2', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.615006');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (10, '主键', '{
  "name": "ID",
  "type": "num",
  "enabled": [
    "s",
    "a",
    "d",
    "r"
  ],
  "fixed": true,
  "width": 66,
  "rwidth": 66
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.610998');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (11, '显示组', '{
  "name": "GID",
  "type": "enum",
  "enabled": [
    "s",
    "a",
    "d",
    "r"
  ],
  "fixed": "right",
  "width": 80,
  "rwidth": 80
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.607986');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (12, '隐藏组', '{
  "name": "GID",
  "enabled": [
    "a"
  ]
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.603979');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (13, '状态', '{
  "name": "STATUS",
  "type": "enum",
  "label": [
    "状态",
    "status"
  ],
  "enabled": [
    "s",
    "a",
    "d"
  ],
  "fixed": "right",
  "width": 55,
  "rwidth": 55,
  "enums": [
    {
      "value": "0",
      "label": "未审核"
    },
    {
      "value": "1",
      "label": "已审核"
    }
  ]
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.600981');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (14, '录入者', '{
  "name": "I_NAME",
  "label": [
    "录入者",
    "Inputer"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 60
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.596960');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (15, '录入时间', '{
  "name": "I_DT",
  "type": "datetime",
  "label": [
    "录入时间",
    "InputDate"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 90
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.593952');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (16, '更新者', '{
  "name": "U_NAME",
  "label": [
    "更新者",
    "Updater"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 60
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.590943');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (17, '更新时间', '{
  "name": "U_DT",
  "type": "datetime",
  "label": [
    "更新时间",
    "UpdateDate"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 90
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.585935');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (18, '审核者', '{
  "name": "V_NAME",
  "label": [
    "审核者",
    "Verifyer"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 60
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.582923');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (19, '审核时间', '{
  "name": "V_DT",
  "type": "datetime",
  "label": [
    "审核日期",
    "VerifyDate"
  ],
  "enabled": [
    "s",
    "a"
  ],
  "width": 90
}', '4', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.578912');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (20, '有效账号-查找', '-- remote get values by label
SELECT `username`
      ,CONCAT(`username`, '' '', `first_name`)
  FROM `auth_user`
 WHERE `is_active` = 1
       AND (
           `username` LIKE {0} ESCAPE ''\\\\''
           OR
           `first_name` LIKE {0} ESCAPE ''\\\\''
       )
LIMIT 100;
-- {1}', '9', '', '2022-05-06 07:54:08', '2022-05-11 15:52:41.078885');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (21, '有效账号-展示', '-- remote get labels by values
SELECT `username`
      ,CONCAT(`username`, '' '', `first_name`)
  FROM `auth_user`
 WHERE `is_active` = 1
       AND `username` IN ({})
LIMIT 100;
-- {}', '9', '', '2022-05-06 07:54:08', '2022-05-10 22:13:52.307292');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (22, '有效角色-查找', '-- remote get values by label
SELECT CAST(`id` AS CHAR)
      ,`name`
  FROM `base_role`
 WHERE `enable` = 1
       AND `name` LIKE {} ESCAPE ''\\\\''
-- {}', '9', '', '2022-05-06 07:54:08', '2022-05-11 15:52:41.070850');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (23, '有效角色-展示', '-- remote get labels by values
SELECT CAST(`id` AS CHAR)
      ,`name`
  FROM `base_role`
 WHERE `enable` = 1
       AND `id` IN ({})
-- {}', '9', '', '2022-05-06 07:54:08', '2022-05-10 22:18:47.824333');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (24, '送审信息', '{
  "DF": {
    "label": "流转记录",
    "type": "text",
    "fixed": "right"
  },
  "TO": {
    "label": "发送给",
    "type": "remote",
    "divider": "送审信息",
    "enabled": [
      "v"
    ],
    "limit": 0,
    "enums": [
      {
        "value": "21",
        "label": "20"
      }
    ]
  },
  "CC": {
    "label": "抄送给",
    "type": "remote",
    "enabled": [
      "v"
    ],
    "limit": 0,
    "enums": [
      {
        "value": "21",
        "label": "20"
      }
    ]
  }
}', '6', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.560862');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (25, '签名信息', '{
  "SIGN": {
    "label": "你的职位",
    "type": "enum",
    "enabled": [
      "v"
    ],
    "enums": [
      {
        "value": "SQ",
        "label": "申请（发起人）"
      },
      {
        "value": "HD",
        "label": "核对（助理）"
      },
      {
        "value": "ZG",
        "label": "主管"
      },
      {
        "value": "SP",
        "label": "审批（总经理）"
      },
      {
        "value": "FH",
        "label": "复核（财务主管）"
      },
      {
        "value": "CN",
        "label": "出纳"
      }
    ]
  },
  "STAMP": {
    "label": "是否签名",
    "type": "enum",
    "enabled": [
      "v"
    ],
    "default": "1",
    "enums": [
      {
        "value": "1",
        "label": "签名"
      },
      {
        "value": "0",
        "label": "不签名"
      }
    ]
  }
}', '6', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.556853');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (26, '审核信息', '{
  "SQ": {
    "label": "申请",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  },
  "HD": {
    "label": "核对",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  },
  "ZG": {
    "label": "主管",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  },
  "SP": {
    "label": "审批",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  },
  "FH": {
    "label": "复核",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  },
  "CN": {
    "label": "出纳",
    "enabled": [
      "s",
      "a",
      "d",
      "r"
    ],
    "width": 65
  }
}', '6', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.552843');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (27, '公司名称', '[
  {
    "value": "10",
    "label": "xx集团"
  },
  {
    "value": "20",
    "label": "xx科技"
  },
  {
    "value": "30",
    "label": "预留1"
  },
  {
    "value": "40",
    "label": "预留2"
  }
]', '4', '', '2022-05-06 07:54:08', '2022-05-14 09:34:02.660239');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (28, '公司列表', '[
  {
    "value": "xx集团",
    "label": "xx集团"
  },
  {
    "value": "xx科技",
    "label": "xx科技"
  },
  {
    "value": "预留1",
    "label": "预留1"
  },
  {
    "value": "预留2",
    "label": "预留2"
  },
  {
    "value": "个人",
    "label": "个人"
  }
]', '4', '', '2022-05-06 07:54:08', '2022-05-14 09:34:02.653222');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (29, '部门列表', '[
  {
    "value": "董事会",
    "label": "董事会",
    "filters": [
      "xx集团"
    ]
  },
  {
    "value": "管理部",
    "label": "管理部"
  },
  {
    "value": "财务部",
    "label": "财务部"
  },
  {
    "value": "行政部",
    "label": "行政部"
  },
  {
    "value": "人事部",
    "label": "人事部"
  },
  {
    "value": "销售部",
    "label": "销售部",
    "filters": [
      "xx集团"
    ]
  },
  {
    "value": "项目中心/研发部",
    "label": "项目中心/研发部",
    "filters": [
      "xx科技"
    ]
  },
  {
    "value": "项目中心/运维部",
    "label": "项目中心/运维部",
    "filters": [
      "xx科技"
    ]
  },
  {
    "value": "信息部",
    "label": "信息部"
  }
]', '4', '', '2022-05-06 07:54:08', '2022-05-14 09:59:02.254754');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (30, '岗位列表', '[
  {
    "value": "董事长",
    "label": "董事长",
    "filters": [
      "董事会"
    ]
  },
  {
    "value": "副董事长",
    "label": "副董事长",
    "filters": [
      "董事会"
    ]
  },
  {
    "value": "秘书",
    "label": "秘书",
    "filters": [
      "董事会"
    ]
  },
  {
    "value": "总经理",
    "label": "总经理",
    "filters": [
      "管理部"
    ]
  },
  {
    "value": "副总经理",
    "label": "副总经理",
    "filters": [
      "管理部"
    ]
  },
  {
    "value": "经理",
    "label": "经理"
  },
  {
    "value": "主管",
    "label": "主管"
  },
  {
    "value": "总监",
    "label": "总监"
  },
  {
    "value": "助理",
    "label": "助理"
  },
  {
    "value": "员工",
    "label": "员工"
  },
  {
    "value": "行政",
    "label": "行政",
    "filters": [
      "行政部"
    ]
  },
  {
    "value": "人事",
    "label": "人事",
    "filters": [
      "人事部"
    ]
  },
  {
    "value": "会计",
    "label": "会计",
    "filters": [
      "财务部"
    ]
  },
  {
    "value": "出纳",
    "label": "出纳",
    "filters": [
      "财务部"
    ]
  }
]', '4', '', '2022-05-06 07:54:08', '2022-05-14 10:02:23.546778');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (31, '公司部门岗位', '{
  "GS": {
    "label": "公司",
    "type": "enum",
    "width": 65,
    "null": false,
    "enums": "#28#"
  },
  "BM": {
    "label": "部门",
    "type": "enum",
    "width": 65,
    "null": false,
    "ref": "GS",
    "enums": "#29#"
  },
  "GW": {
    "label": "岗位",
    "type": "enum",
    "width": 65,
    "null": false,
    "ref": "BM",
    "enums": "#30#"
  }
}', '6', '', '2022-05-06 07:54:08', '2022-05-06 23:15:45.525763');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (32, '数据鉴权-行政', '(
               -- 管理员看所有
               {username} IN (''admin'')
               OR
			   -- 本人可以查看
               `I_NAME` = {username}
               OR
			   -- 已提交申请的
               (
                   `STATUS` <> ''0''
                   AND
                   (
                       -- 相关人员可以查看
                       EXISTS (SELECT 1 FROM `V_COMPANY_STAFF_RELATION` WHERE `STAFF_ID_L` = {username} AND `STAFF_ID` = a.`I_NAME`)
					   -- 行政人员可以查看
                       OR
                       (
                           EXISTS (SELECT 1 FROM `V_USER_ROLE` WHERE `user` = {username} AND `name` = ''xx集团-行政部'')
						   OR
                           EXISTS (SELECT 1 FROM `V_USER_ROLE` WHERE `user` = {username} AND `name` = ''xx科技-行政部'' AND `I_NAME` LIKE ''20%'')
                       )
					   OR
					   -- 特殊账号可以查看
                       {username} IN (''100001'')
                   )
               )
           )', '9', '', '2022-05-06 07:54:08', '2022-05-14 18:11:28.889465');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (33, '数据鉴权-送审', '(
               -- 管理员看所有
               {username} IN (''admin'')
               OR
			   -- 本人可以查看
               `I_NAME` = {username}
               OR
			   -- 已提交申请的
               (
                   `STATUS` <> ''0''
                   AND
                   (
                       -- 送审列表人员可以查看
                       LOCATE({username}, `DF`) > 0
					   OR
					   -- 特殊账号可以查看
                       {username} IN (''100001'')
                   )
               )
           )', '9', '', '2022-05-08 18:09:38.334310', '2022-05-14 19:03:31.087346');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (34, '预留3', '{}', '1', '', '2022-05-08 18:17:05.008564', '2022-05-10 16:39:29.258530');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (35, '预留4', '{}', '1', '', '2022-05-10 14:13:13.653102', '2022-05-10 16:39:29.255525');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (36, '预留5', '{}', '1', '', '2022-05-10 14:13:33.861655', '2022-05-10 16:39:29.252518');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (37, '预留6', '{}', '1', '', '2022-05-10 14:13:45.533053', '2022-05-10 16:39:29.249519');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (38, '预留7', '{}', '1', '', '2022-05-10 14:13:49.468036', '2022-05-10 16:39:29.245499');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (39, '预留8', '{}', '1', '', '2022-05-10 14:13:53.582117', '2022-05-10 16:39:29.240489');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (40, '预留9', '{}', '1', '', '2022-05-10 14:13:58.068920', '2022-05-10 16:39:29.236474');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (41, '测试', '{}', '1', '', '2022-05-10 14:15:03.971033', '2022-05-10 16:39:29.229489');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (42, '系统反馈', '{
  "obj": "`T_SYSTEM_FEEDBACK`",
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "label": "处理中",
            "value": "0"
          },
          {
            "label": "已完结",
            "value": "1"
          }
        ]
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "CLS": {
      "label": "类别",
      "type": "enum",
      "width": 80,
      "null": false,
      "enums": [
        {
          "label": "优化建议",
          "value": "优化建议"
        },
        {
          "label": "系统异常",
          "value": "系统异常"
        },
        {
          "label": "新增功能",
          "value": "新增功能"
        },
        {
          "label": "其它",
          "value": "其它"
        }
      ]
    },
    "TITLE": {
      "label": "主题",
      "type": "text",
      "null": false,
      "cell_style": "white-space: pre-wrap;"
    },
    "CONTENT": {
      "label": "详情",
      "type": "richtext",
      "enabled": [
        "s",
        "e",
        "a",
        "r"
      ],
      "tooltip": false,
      "null": false
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "layouts": {
    "detail": {
      "colWidths": [
        1000
      ],
      "trs": [
        {
          "tds": [
            {
              "keys": "CONTENT"
            }
          ]
        }
      ]
    }
  },
  "relations": {
    "detail": {
      "type": "rLayout",
      "kwargs": {
        "layout": "detail"
      }
    }
  }
}', '1', '', '2022-05-10 16:22:00.268887', '2022-05-14 13:11:05.535623');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (43, '文件管理', '{
  "obj": "`T_COMPANY_FILES`",
  "self": {
    "columns": {
      "status": {
        "funcs": [
          {
            "func": "condition_style",
            "args": [
              {
                "in": "color: red; font-weight: bold;"
              },
              [
                "无效"
              ]
            ]
          }
        ],
        "enums": [
          {
            "value": "0",
            "label": "无效"
          },
          {
            "value": "1",
            "label": "有效"
          }
        ]
      }
    }
  },
  "config": {
    "selectable": false
  },
  "enable_add": false,
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "NAME": {
      "label": "文件名",
      "width": 150
    },
    "PATH": {
      "label": "路径",
      "link": "OAExend:{0}"
    },
    "SIZE": {
      "label": "大小（MB）",
      "type": "num",
      "width": 80
    },
    "ADT": {
      "label": "访问日期",
      "type": "datetime",
      "width": 160
    },
    "MDT": {
      "label": "文件修改日期",
      "type": "datetime",
      "width": 160
    },
    "CDT": {
      "label": "权限修改日期",
      "type": "datetime",
      "width": 160
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "e_list_status": false,
  "v_list_status": false
}', '1', '', '2022-05-10 16:22:01.813290', '2022-05-14 13:20:02.795464');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (44, '事件管理', '{
  "obj": "`T_COMPANY_EVENT`",
  "sqls": {
    "rolename_display": "`FN_GET_ROLE_NAME`(ROLES)",
    "username_display": "`FN_GET_USER_NAME`(USERS)"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "EVENT": {
      "label": "事件",
      "placeholder": "应简洁明了，不超过60个字符",
      "null": false,
      "ranges": [
        "1",
        "64"
      ]
    },
    "rolename": {
      "label": "角色",
      "name": "ROLES",
      "enabled": [
        "a",
        "d",
        "r"
      ],
      "expression": "rolename_display"
    },
    "ROLES": {
      "label": "角色",
      "type": "remote",
      "enabled": [
        "e"
      ],
      "limit": 0,
      "enums": [
        {
          "value": "23",
          "label": "22"
        }
      ]
    },
    "username": {
      "label": "账号",
      "name": "USERS",
      "enabled": [
        "a",
        "d",
        "r"
      ],
      "expression": "username_display"
    },
    "USERS": {
      "label": "账号",
      "type": "remote",
      "enabled": [
        "e"
      ],
      "limit": 0,
      "enums": [
        {
          "value": "21",
          "label": "20"
        }
      ]
    },
    "REMARK": {
      "label": "备注",
      "type": "text"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": {
      "STATUS": "IF(`STATUS` = ''0'', ''1'', ''0'')"
    }
  },
  "v_cmds": [
    {
      "label": "更改状态",
      "command": "0",
      "tips": "此操作将反转数据状态，请确认是否继续？"
    }
  ]
}', '1', '', '2022-05-10 16:22:03.612939', '2022-05-14 13:20:02.789446');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (45, '通讯录', '{
  "obj": "`T_COMPANY_STAFF`",
  "enable_all": false,
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "未启用"
          },
          {
            "value": "1",
            "label": "已启用"
          },
          {
            "value": "2",
            "label": "已离职"
          }
        ]
      }
    }
  },
  "sqls": {
    "ips_search": "EXISTS (SELECT 1 FROM `auth_user` b WHERE a.`STAFF_ID` = b.`username` AND {{}})",
    "ips_display": "(SELECT `email` FROM `auth_user` b WHERE a.`STAFF_ID` = b.`username`)",
    "roles_search": "EXISTS (SELECT 1 FROM `base_role` b WHERE {{}} AND b.`id` IN (SELECT value FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(a.`ROLES`, '','', `NUM` + 1), '','', -1)) AS value FROM `T_SYSTEM_AUXILIARY` WHERE `NUM` <= FN_COUNT_STR(a.`ROLES`, '','') AND `TYPE` = ''P'') T))",
    "roles_display": "`FN_GET_ROLE_NAME`(`ROLES`)",
    "cross_update": "#47#"
  },
  "tools": {
    "structure": {
      "label": "组织架构",
      "width": "600px",
      "kwargs": {
        "key": "POSITION",
        "gid": "待子配置覆盖，用于查询此组织架构下的通讯录数据",
        "idx": "待子配置覆盖，用于更新此配置文件中的组织架构配置"
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "STAFF_ID": {
      "label": "工号",
      "width": 60,
      "placeholder": "四位数的编号：8888",
      "regexs": [
        [
          "{0}只需输入四位数字，前两位会自动生成",
          "^\\\\d{4}$",
          "工号格式校验"
        ]
      ]
    },
    "POSITION": {
      "label": "岗位",
      "type": "cascade",
      "width": 150,
      "divider": "岗位信息",
      "enums": []
    },
    "LEADERS": {
      "label": "主管",
      "type": "remote",
      "width": 100,
      "limit": 0,
      "enums": [
        {
          "value": "21",
          "label": "20"
        }
      ]
    },
    "FULL_NAME": {
      "name": "FULL_NAME",
      "label": "姓名",
      "width": 55,
      "divider": "个人信息",
      "null": false
    },
    "ABBR_NAME": {
      "label": "称谓",
      "width": 55
    },
    "EMAIL": {
      "label": "邮箱",
      "width": 150
    },
    "TEL": {
      "label": "分机",
      "width": 50
    },
    "MP": {
      "label": "手机",
      "width": 150
    },
    "NAMES": {
      "label": "角色",
      "name": "name",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "link_query": "roles_search",
      "expression": "roles_display"
    },
    "ROLES": {
      "label": "角色",
      "type": "remote",
      "enabled": [
        "e"
      ],
      "divider": "权限",
      "limit": 0,
      "enums": [
        {
          "value": "23",
          "label": "22"
        }
      ]
    },
    "IP": {
      "label": "最后登录的IP",
      "width": 120,
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "IPS": {
      "name": "email",
      "label": "绑定地址",
      "link_query": "ips_search",
      "width": 120,
      "expression": "ips_display"
    },
    "PWD": {
      "label": "重置密码",
      "type": "enum",
      "expression": "NULL",
      "enabled": [
        "e"
      ],
      "enums": [
        {
          "value": "Y",
          "label": "Y"
        }
      ]
    },
    "REMARK": {
      "type": "text",
      "label": "备注"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "e_conf": {
    "default_set": false,
    "func_a": [
      {
        "func": "apps.datacenter.hooks.flush_perm",
        "agrs": [
          "ROLES",
          "STAFF_ID"
        ]
      }
    ]
  },
  "e_list_status": {
    "0": [
      "STAFF_ID",
      "POSITION",
      "LEADERS",
      "FULL_NAME",
      "ABBR_NAME",
      "EMAIL",
      "TEL",
      "MP",
      "ROLES",
      "REMARK"
    ],
    "1": [
      "POSITION",
      "LEADERS",
      "FULL_NAME",
      "ABBR_NAME",
      "EMAIL",
      "TEL",
      "MP",
      "ROLES",
      "IPS",
      "PWD",
      "REMARK"
    ],
    "2": []
  },
  "e_list_cross": {
    "sql": "cross_update",
    "keys": [
      "IPS",
      "PWD"
    ]
  },
  "e_list_super": [
    "POSITION",
    "LEADERS",
    "FULL_NAME",
    "ABBR_NAME",
    "EMAIL",
    "TEL",
    "MP",
    "ROLES",
    "REMARK"
  ],
  "v_conf": {
    "default_set": {
      "STATUS": "CASE `STATUS` WHEN ''0'' THEN ''1'' ELSE ''2'' END"
    }
  },
  "v_list_status": {
    "0": []
  }
}', '1', '', '2022-05-10 16:22:04.810906', '2022-05-12 16:05:01.089126');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (46, '通讯录-只读', '{
  "config": {
    "selectable": false
  },
  "enable_add": false,
  "sqls": {
    "default_condition": "`STATUS` = ''1''"
  },
  "tools": null,
  "columns": {
    "COMPANY": {
      "name": "GID",
      "type": "enum",
      "label": "公司",
      "fixed": "right",
      "width": 80,
      "link": "/datacenter/staff?gid={0}&id={1}&_init_pk={1}&_init_status=1",
      "link_keys": [
        "GID",
        "id"
      ],
      "enums": "#27#"
    },
    "GID": {
      "name": "GID",
      "enabled": [
        "a"
      ]
    }
  },
  "s_list": [
    "id",
    "STAFF_ID",
    "POSITION",
    "LEADERS",
    "FULL_NAME",
    "ABBR_NAME",
    "EMAIL",
    "TEL",
    "MP",
    "REMARK",
    "COMPANY"
  ],
  "d_a_list": [
    "id",
    "STAFF_ID",
    "POSITION",
    "LEADERS",
    "FULL_NAME",
    "ABBR_NAME",
    "EMAIL",
    "TEL",
    "MP",
    "REMARK",
    "COMPANY",
    "GID"
  ],
  "e_list_status": false,
  "v_list_status": false
}', '1', '', '2022-05-10 16:22:06.546227', '2022-05-10 16:31:04.415527');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (47, '通讯录-跨表更新', 'UPDATE `auth_user`
   SET `email` = CASE WHEN {{0}} IS NULL THEN `email` ELSE {{0}} END
      ,`password` = CASE WHEN {{1}} IS NULL THEN `password` ELSE ''pbkdf2_sha256$320000$yyeI7jFNlmpe4NZXjrbnZa$iEGicA/QMH9dUaom2WYPcGUTjJ2eEo4lNuuoe0Yo7NU='' END
 WHERE `username` IN (SELECT `STAFF_ID` FROM `T_COMPANY_STAFF` WHERE `ID` = {pk})', '9', '', '2022-05-10 16:22:07.804203', '2022-05-10 16:33:01.398297');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (48, '通讯录-xx集团', '{
  "tools": {
    "structure": {
      "kwargs": {
        "gid": 10,
        "idx": 49
      }
    }
  },
  "columns": {
    "POSITION": {
      "enums": "#49#"
    }
  }
}', '1', '', '2022-05-10 16:22:11.713746', '2022-05-10 17:01:13.905198');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (49, '组织架构-xx集团', '[
  {
    "value": "董事会",
    "label": "董事会",
    "children": [
      {
        "value": "董事长",
        "label": "董事长"
      },
      {
        "value": "副董事长",
        "label": "副董事长"
      },
      {
        "value": "秘书",
        "label": "秘书"
      }
    ]
  },
  {
    "value": "管理部",
    "label": "管理部",
    "children": [
      {
        "value": "总经理",
        "label": "总经理"
      },
      {
        "value": "副总经理",
        "label": "副总经理"
      },
      {
        "value": "秘书",
        "label": "秘书"
      }
    ]
  },
  {
    "value": "财务部",
    "label": "财务部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "会计",
        "label": "会计"
      },
      {
        "value": "出纳",
        "label": "出纳"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "行政部",
    "label": "行政部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "行政",
        "label": "行政"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "人事部",
    "label": "人事部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "人事",
        "label": "人事"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "销售部",
    "label": "销售部",
    "children": [
      {
        "value": "总监",
        "label": "总监"
      },
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "信息部",
    "label": "信息部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  }
]', '4', '', '2022-05-10 16:22:13.797498', '2022-05-14 10:16:48.405134');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (50, '通讯录-xx科技', '{
  "tools": {
    "structure": {
      "kwargs": {
        "gid": 20,
        "idx": 51
      }
    }
  },
  "columns": {
    "POSITION": {
      "enums": "#51#"
    }
  }
}', '1', '', '2022-05-10 16:22:15.563483', '2022-05-10 17:01:13.899182');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (51, '组织架构-xx科技', '[
  {
    "value": "管理部",
    "label": "管理部",
    "children": [
      {
        "value": "总经理",
        "label": "总经理"
      },
      {
        "value": "副总经理",
        "label": "副总经理"
      },
      {
        "value": "秘书",
        "label": "秘书"
      }
    ]
  },
  {
    "value": "财务部",
    "label": "财务部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "会计",
        "label": "会计"
      },
      {
        "value": "出纳",
        "label": "出纳"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "行政部",
    "label": "行政部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "行政",
        "label": "行政"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "人事部",
    "label": "人事部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "主管",
        "label": "主管"
      },
      {
        "value": "助理",
        "label": "助理"
      },
      {
        "value": "人事",
        "label": "人事"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  },
  {
    "value": "项目中心",
    "label": "项目中心",
    "children": [
      {
        "value": "研发部",
        "label": "研发部",
        "children": [
          {
            "value": "经理",
            "label": "经理"
          },
          {
            "value": "一组主管",
            "label": "一组主管"
          },
          {
            "value": "二组主管",
            "label": "二组主管"
          },
          {
            "value": "三组主管",
            "label": "三组主管"
          },
          {
            "value": "员工",
            "label": "员工"
          }
        ]
      },
      {
        "value": "运维部",
        "label": "运维部",
        "children": [
          {
            "value": "经理",
            "label": "经理"
          },
          {
            "value": "助理",
            "label": "助理"
          },
          {
            "value": "员工",
            "label": "员工"
          }
        ]
      }
    ]
  },
  {
    "value": "信息部",
    "label": "信息部",
    "children": [
      {
        "value": "经理",
        "label": "经理"
      },
      {
        "value": "员工",
        "label": "员工"
      }
    ]
  }
]', '4', '', '2022-05-10 16:22:19.594950', '2022-05-14 10:07:38.031213');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (52, '通讯录-预留1', '{
  "tools": {
    "structure": {
      "kwargs": {
        "gid": 30,
        "idx": 53
      }
    }
  },
  "columns": {
    "POSITION": {
      "enums": "#53#"
    }
  }
}', '1', '', '2022-05-10 16:35:00.383584', '2022-05-14 09:21:21.801809');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (53, '组织架构-预留1', '[
  {
    "value": "xx部门",
    "label": "xx部门",
    "children": [
      {
        "value": "xxg岗位",
        "label": "xxg岗位"
      }
    ]
  }
]', '4', '', '2022-05-10 16:35:04.170060', '2022-05-14 09:21:21.798800');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (54, '通讯录-预留2', '{
  "tools": {
    "structure": {
      "kwargs": {
        "gid": 40,
        "idx": 55
      }
    }
  },
  "columns": {
    "POSITION": {
      "enums": "#55#"
    }
  }
}', '1', '', '2022-05-10 16:35:08.589383', '2022-05-14 09:21:21.794790');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (55, '组织架构-预留2', '[
  {
    "value": "xx部门",
    "label": "xx部门",
    "children": [
      {
        "value": "xxg岗位",
        "label": "xxg岗位"
      }
    ]
  }
]', '4', '', '2022-05-10 16:35:37.427800', '2022-05-14 09:21:21.789776');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (56, '日程管理', '{
  "obj": "`T_COMPANY_CALENDAR`",
  "enable_all": false,
  "sqls": {
    "limit_condition": "`CLS` IN (''2'', ''3'') AND `I_NAME` IN ({username})"
  },
  "self": {
    "columns": {
      "status": {
        "funcs": [
          {
            "func": "condition_style",
            "args": [
              {
                "in": "color: red; font-weight: bold;"
              },
              [
                "无效"
              ]
            ]
          }
        ],
        "enums": [
          {
            "value": "0",
            "label": "无效"
          },
          {
            "value": "1",
            "label": "有效"
          }
        ]
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "NAME": {
      "label": "标题",
      "width": 120,
      "placeholder": "不超过8个字",
      "null": false,
      "ranges": [
        "",
        "8"
      ]
    },
    "BEGIN_DT": {
      "label": "开始时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "END_DT": {
      "label": "结束时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "CLS": {
      "label": "类型",
      "type": "enum",
      "width": 40,
      "default": "2",
      "null": false,
      "enums": [
        {
          "value": "2",
          "label": "备忘"
        },
        {
          "value": "3",
          "label": "提醒"
        }
      ]
    },
    "REMARK": {
      "label": "备注",
      "type": "text",
      "style": "width: 60vw;",
      "cell_style": "white-space: pre-wrap;"
    },
    "WARN_DAY": {
      "label": "提前提醒天数",
      "type": "num",
      "width": 55,
      "placeholder": "默认是当天"
    },
    "WARN_TIMES": {
      "label": "提醒次数",
      "type": "num",
      "width": 55,
      "placeholder": "默认1次，一天一次",
      "ranges": [
        "1",
        ""
      ]
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": {
      "STATUS": "CASE WHEN `STATUS` = ''0'' THEN ''1'' ELSE ''0'' END"
    }
  },
  "v_cmds": [
    {
      "label": "更改状态",
      "command": "0",
      "tips": "此操作将反转数据状态，请确认是否继续？"
    }
  ],
  "v_list_status": {
    "0": [],
    "1": []
  }
}', '1', '', '2022-05-10 16:35:45.449186', '2022-05-14 09:18:13.308692');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (57, '待办事项', '{
  "obj": "`T_COMPANY_TODO`",
  "orders": "`PRIORITY`, `ID` DESC",
  "sqls": {
    "limit_condition": "`I_NAME` IN ({username})"
  },
  "self": {
    "columns": {
      "status": {
        "funcs": [
          {
            "func": "condition_style",
            "args": [
              {
                "in": "color: red; font-weight: bold;"
              },
              [
                "未完成"
              ]
            ]
          }
        ],
        "enums": [
          {
            "value": "0",
            "label": "未完成"
          },
          {
            "value": "1",
            "label": "已完成"
          }
        ]
      }
    }
  },
  "tools": {
    "enum": {
      "label": "筛选项",
      "width": "600px",
      "kwargs": {
        "keys": {
          "TAG": 53
        }
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "TAG": {
      "label": "标签",
      "type": "enum",
      "width": 120,
      "create": true,
      "placeholder": "不超过8个字",
      "null": false,
      "enums": [
        {
          "value": "直通车",
          "label": "直通车"
        },
        {
          "value": "文档编写",
          "label": "文档编写"
        },
        {
          "value": "功能开发",
          "label": "功能开发"
        },
        {
          "value": "功能优化",
          "label": "功能优化"
        },
        {
          "value": "数据处理",
          "label": "数据处理"
        },
        {
          "value": "数据采集",
          "label": "数据采集"
        }
      ]
    },
    "PRIORITY": {
      "label": "优先级",
      "type": "num",
      "width": 50,
      "default": "100",
      "null": false
    },
    "CONTENT": {
      "label": "内容",
      "type": "text",
      "cell_style": "white-space: pre-wrap;",
      "null": false,
      "ranges": [
        "",
        "1024"
      ]
    },
    "ATTACHMENTS": {
      "type": "file",
      "label": "附件",
      "width": 400,
      "tooltip": false,
      "limit": 0
    },
    "URL": {
      "label": "链接",
      "style": "width: 820px",
      "width": 40,
      "link": "{0}",
      "link_name": "查看"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": {
      "STATUS": "CASE WHEN [STATUS] = ''0'' THEN ''1'' ELSE ''0'' END"
    },
    "msg": false
  },
  "v_cmds": [
    {
      "label": "更改状态",
      "command": "0",
      "tips": "此操作将反转数据状态，请确认是否继续？"
    }
  ],
  "v_list_status": {
    "0": [],
    "1": []
  }
}', '1', '', '2022-05-10 16:41:28.552627', '2022-05-14 09:18:13.304685');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (58, '通知', '{
  "obj": "`T_COMPANY_NOTICE`",
  "self": {
    "columns": {
      "status": {
        "funcs": [
          {
            "func": "condition_style",
            "args": [
              {
                "in": "color: red; font-weight: bold;"
              },
              [
                "未发布"
              ]
            ]
          }
        ],
        "enums": [
          {
            "value": "0",
            "label": "未发布"
          },
          {
            "value": "1",
            "label": "已发布"
          }
        ]
      }
    }
  },
  "layouts": {
    "detail": {
      "tableStyle": "font-family: KaiTi; width:1400px; margin: 10px;",
      "colWidths": [
        1000
      ],
      "trs": [
        {
          "tds": [
            {
              "keys": [
                "CONTENT"
              ]
            }
          ]
        }
      ]
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "TITLE": {
      "label": "标题",
      "null": false
    },
    "CONTENT": {
      "label": "内容",
      "type": "richtext",
      "enabled": [
        "s",
        "a",
        "e"
      ],
      "null": false
    },
    "GROUPS": {
      "label": "公司",
      "type": "enum",
      "width": 250,
      "limit": 0,
      "enums": "#27#"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "relations": {
    "detail": {
      "type": "rLayout",
      "kwargs": {
        "layout": "detail"
      }
    }
  },
  "v_conf": {
    "default_set": {
      "STATUS": "CASE WHEN `STATUS` = ''0'' THEN ''1'' ELSE ''0'' END"
    }
  },
  "v_cmds": [
    {
      "command": "0",
      "label": "更改状态",
      "tips": "此操作将反转数据状态，请确认是否继续？"
    }
  ],
  "v_list_status": {
    "0": [],
    "1": []
  }
}', '1', '', '2022-05-10 16:41:32.445541', '2022-05-14 09:18:13.300670');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (59, '通知-只读', '{
  "self": null,
  "config": {
    "selectable": false
  },
  "sqls": {
    "default_condition": "`STATUS` = ''1''",
    "limit_condition": "(IFNULL(`GROUPS`, '''') = '''' OR `GROUPS` LIKE CONCAT(''%'', SUBSTRING({username}, 1, 2), ''%''))"
  },
  "key_gid": false,
  "key_status": false,
  "enable_add": false,
  "s_list": [
    "id",
    "TITLE",
    "CONTENT"
  ],
  "d_a_list": [
    "id",
    "TITLE",
    "CONTENT",
    "iname",
    "idt",
    "uname",
    "udt",
    "vname",
    "vdt"
  ],
  "e_list_status": false,
  "v_list_status": false
}', '2', '', '2022-05-10 16:41:36.523858', '2022-05-14 09:21:21.783764');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (60, '节假日', '{
  "obj": "`T_COMPANY_CALENDAR`",
  "enable_all": false,
  "sqls": {
    "limit_condition": "`CLS` IN (''0'', ''1'')"
  },
  "self": {
    "columns": {
      "status": {
        "funcs": [
          {
            "func": "condition_style",
            "args": [
              {
                "in": "color: red; font-size: 18px; font-weight: bold;"
              },
              [
                "无效"
              ]
            ]
          }
        ],
        "enums": [
          {
            "value": "0",
            "label": "无效"
          },
          {
            "value": "1",
            "label": "有效"
          }
        ]
      }
    }
  },
  "tools": {
    "enum": {
      "label": "筛选项",
      "width": "600px",
      "kwargs": {
        "keys": {
          "NAME": 56
        }
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "NAME": {
      "label": "名称",
      "type": "enum",
      "width": 80,
      "null": false,
      "enums": [
        {
          "value": "元旦节",
          "label": "元旦节"
        },
        {
          "value": "年夜饭",
          "label": "年夜饭"
        },
        {
          "value": "年假",
          "label": "年假"
        },
        {
          "value": "除夕",
          "label": "除夕"
        },
        {
          "value": "春节",
          "label": "春节"
        },
        {
          "value": "开工大吉",
          "label": "开工大吉"
        },
        {
          "value": "清明节",
          "label": "清明节"
        },
        {
          "value": "劳动节",
          "label": "劳动节"
        },
        {
          "value": "端午节",
          "label": "端午节"
        },
        {
          "value": "中秋节",
          "label": "中秋节"
        },
        {
          "value": "国庆节",
          "label": "国庆节"
        },
        {
          "value": "上班",
          "label": "上班"
        },
        {
          "value": "放假",
          "label": "放假"
        },
        {
          "value": "半天假",
          "label": "半天假"
        },
        {
          "value": "月例会",
          "label": "月例会"
        }
      ]
    },
    "BEGIN_DT": {
      "label": "开始时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "END_DT": {
      "label": "结束时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "CLS": {
      "label": "类型",
      "type": "enum",
      "width": 40,
      "default": "0",
      "null": false,
      "enums": [
        {
          "value": "0",
          "label": "放假"
        },
        {
          "value": "1",
          "label": "上班"
        }
      ]
    },
    "REMARK": {
      "label": "备注",
      "type": "text",
      "cell_style": "white-space: pre-wrap;"
    },
    "GROUPS": {
      "label": "公司",
      "type": "enum",
      "width": 250,
      "limit": 0,
      "enums": "#27#"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": {
      "STATUS": "CASE WHEN `STATUS` = ''0'' THEN ''1'' ELSE ''0'' END"
    }
  },
  "v_cmds": [
    {
      "label": "更改状态",
      "command": "0",
      "tips": "此操作将反转数据状态，请确认是否继续？"
    }
  ],
  "v_list_status": {
    "0": [],
    "1": []
  }
}', '1', '', '2022-05-10 16:41:40.580019', '2022-05-14 09:18:13.290644');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (61, '请假条', '{
  "obj": "`T_COMPANY_LEAVE_INFO`",
  "config": {
    "clearvform": true
  },
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "待审核"
          },
          {
            "value": "2",
            "label": "已同意"
          }
        ]
      }
    }
  },
  "sqls": {
    "limit_condition": "#32#"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "CLS": {
      "label": "分类",
      "type": "enum",
      "width": 45,
      "null": false,
      "enums": [
        {
          "label": "事假",
          "value": "事假"
        },
        {
          "label": "病假",
          "value": "病假"
        },
        {
          "label": "丧假",
          "value": "丧假"
        },
        {
          "label": "婚嫁",
          "value": "婚嫁"
        },
        {
          "label": "产假",
          "value": "产假"
        }
      ]
    },
    "BEGIN_DT": {
      "label": "开始时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "END_DT": {
      "label": "结束时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "TOTAL": {
      "label": "累计时间(分钟)",
      "type": "num",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 108
    },
    "REASON": {
      "label": "事由",
      "type": "text",
      "cell_style": "white-space: pre-wrap;",
      "null": false
    },
    "ATTACHMENTS": {
      "label": "附件",
      "type": "file",
      "tooltip": false,
      "limit": 0
    },
    "REMARK": {
      "type": "text",
      "label": "备注",
      "cell_style": "white-space: pre-wrap;",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SQ": {
      "label": "申请人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "ZG": {
      "label": "批准人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "三天以内主管审核，超过三天总经理审批"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = ''a''",
    "b": "`STATUS` = ''0'', `SQ` = NULL, `ZG` = NULL"
  },
  "e_list_status": {
    "1": [],
    "2": []
  },
  "v_list_status": {
    "0": [],
    "1": [
      "REMARK"
    ]
  }
}', '1', '', '2022-05-10 16:41:44.713034', '2022-05-14 13:44:10.635220');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (62, '加班单', '{
  "obj": "`T_COMPANY_OVERTIME_INFO`",
  "config": {
    "clearvform": true
  },
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "待审核"
          },
          {
            "value": "2",
            "label": "已同意"
          }
        ]
      }
    }
  },
  "sqls": {
    "limit_condition": "#32#"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "BEGIN_DT": {
      "label": "开始时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "END_DT": {
      "label": "结束时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "TOTAL": {
      "label": "累计时间(分钟)",
      "type": "num",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 108
    },
    "REASON": {
      "label": "事由",
      "type": "text",
      "cell_style": "white-space: pre-wrap;",
      "null": false
    },
    "REMARK": {
      "type": "text",
      "label": "备注",
      "cell_style": "white-space: pre-wrap;",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SQ": {
      "label": "申请人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "ZG": {
      "label": "批准人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "请确认是否继续？"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = ''a''",
    "b": "`STATUS` = ''0'', `SQ` = NULL, `ZG` = NULL"
  },
  "e_list_status": {
    "1": [],
    "2": []
  },
  "v_list_status": {
    "0": [],
    "1": [
      "REMARK"
    ]
  }
}', '1', '', '2022-05-10 16:41:48.510892', '2022-05-14 20:08:35.948706');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (63, '调休单', '{
  "obj": "`T_COMPANY_DAYOFF_INFO`",
  "config": {
    "clearvform": true
  },
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "待审核"
          },
          {
            "value": "2",
            "label": "已同意"
          }
        ]
      }
    }
  },
  "sqls": {
    "limit_condition": "#32#"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "BEGIN_DT": {
      "label": "开始时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "END_DT": {
      "label": "结束时间",
      "type": "datetime",
      "width": 150,
      "null": false
    },
    "TOTAL": {
      "label": "累计时间(分钟)",
      "type": "num",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 108
    },
    "REMAIN": {
      "label": "剩余时间(分钟)",
      "type": "num",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 108
    },
    "REASON": {
      "label": "事由",
      "type": "text",
      "cell_style": "white-space: pre-wrap;",
      "null": false
    },
    "REMARK": {
      "type": "text",
      "label": "备注",
      "cell_style": "white-space: pre-wrap;",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SQ": {
      "label": "申请人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "ZG": {
      "label": "批准人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "三天以内主管审核，超过三天总经理审批"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = ''a''",
    "b": "`STATUS` = ''0'', `SQ` = NULL, `ZG` = NULL"
  },
  "e_list_status": {
    "1": [],
    "2": []
  },
  "v_list_status": {
    "0": [],
    "1": [
      "REMARK"
    ]
  }
}', '1', '', '2022-05-10 16:41:54.680131', '2022-05-14 20:10:16.444131');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (64, '漏打卡', '{
  "obj": "`T_COMPANY_FORGET_PUNCH`",
  "config": {
    "clearvform": true
  },
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "待审核"
          },
          {
            "value": "2",
            "label": "已同意"
          }
        ]
      }
    }
  },
  "sqls": {
    "limit_condition": "#32#"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "ED": {
      "type": "date",
      "label": "日期",
      "width": 90,
      "null": false
    },
    "CLS": {
      "type": "enum",
      "label": "时间",
      "width": 100,
      "null": false,
      "limit": 0,
      "enums": [
        {
          "value": "上午",
          "label": "上午"
        },
        {
          "value": "下午",
          "label": "下午"
        }
      ]
    },
    "REASON": {
      "type": "text",
      "label": "事由",
      "cell_style": "white-space: pre-wrap;",
      "null": false
    },
    "REMARK": {
      "type": "text",
      "label": "备注",
      "cell_style": "white-space: pre-wrap;",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SQ": {
      "label": "申请人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "ZG": {
      "label": "批准人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "请确认是否继续？"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = ''a''",
    "b": "`STATUS` = ''0'', `SQ` = NULL, `ZG` = NULL"
  },
  "e_list_status": {
    "1": [],
    "2": []
  },
  "v_list_status": {
    "0": [],
    "1": [
      "REMARK"
    ]
  }
}', '1', '', '2022-05-10 16:41:59.076234', '2022-05-14 20:10:16.438105');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (65, '出门条', '{
  "obj": "`T_COMPANY_OUT_SIGN`",
  "config": {
    "clearvform": true
  },
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "待审核"
          },
          {
            "value": "2",
            "label": "已同意"
          }
        ]
      }
    }
  },
  "sqls": {
    "limit_condition": "#32#"
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "EDT": {
      "type": "datetime",
      "label": "日期",
      "width": 150,
      "null": false
    },
    "REASON": {
      "type": "text",
      "label": "事由",
      "cell_style": "white-space: pre-wrap;",
      "null": false
    },
    "REMARK": {
      "type": "text",
      "label": "备注",
      "cell_style": "white-space: pre-wrap;",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SQ": {
      "label": "申请人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "ZG": {
      "label": "批准人",
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ],
      "width": 100
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "请确认是否继续？"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = ''a''",
    "b": "`STATUS` = ''0'', `SQ` = NULL, `ZG` = NULL"
  },
  "e_list_status": {
    "1": [],
    "2": []
  },
  "v_list_status": {
    "0": [],
    "1": [
      "REMARK"
    ]
  }
}', '1', '', '2022-05-10 16:42:03.607501', '2022-05-14 20:10:16.432125');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (66, '信息表', '{
  "obj": "`V_T_COMPANY_STAFF_INFO`",
  "table": "`T_COMPANY_STAFF_INFO`",
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "在职"
          },
          {
            "value": "1",
            "label": "离职"
          }
        ]
      }
    }
  },
  "config": {
    "selectable": false
  },
  "autocompletes": {
    "staff_info": {
      "label": "CONCAT(`XM`, ''（'',  `RZSJ`, ''）'')",
      "value": "`ID`"
    }
  },
  "tools": {
    "attendance": {
      "label": "考勤汇总",
      "width": "fit-content",
      "kwargs": {
        "excluded": [
          "100001"
        ]
      }
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "BH": {
      "label": "编号",
      "type": "num",
      "width": 50
    },
    "GH": {
      "label": "工号",
      "type": "remote",
      "width": 60,
      "enums": [
        {
          "label": "20",
          "value": "21"
        }
      ]
    },
    "GS": {
      "label": "公司",
      "type": "enum",
      "width": 65,
      "divider": "",
      "null": false,
      "enums": "#28#"
    },
    "BM": {
      "label": "部门",
      "width": 65
    },
    "XM": {
      "label": "姓名",
      "width": 55,
      "null": false
    },
    "RZSJ": {
      "label": "入职时间",
      "type": "date",
      "width": 90,
      "null": false
    },
    "HTYXQ": {
      "label": "合同效期至",
      "type": "date",
      "width": 90
    },
    "XB": {
      "label": "性别",
      "type": "enum",
      "width": 35,
      "enums": [
        {
          "value": "男",
          "label": "男"
        },
        {
          "value": "女",
          "label": "女"
        }
      ],
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "SFZH": {
      "label": "身份证号",
      "null": false,
      "ranges": [
        "18",
        "18"
      ]
    },
    "SJHM": {
      "label": "手机号码",
      "width": 100
    },
    "JZGW": {
      "label": "就职岗位",
      "width": 70
    },
    "GL": {
      "label": "工龄",
      "type": "num",
      "width": 40,
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "NL": {
      "label": "年龄",
      "type": "num",
      "width": 40,
      "enabled": [
        "s",
        "a",
        "d",
        "r"
      ]
    },
    "JG": {
      "label": "籍贯",
      "width": 40,
      "divider": ""
    },
    "HJ": {
      "label": "户籍",
      "width": 40
    },
    "HY": {
      "label": "婚姻",
      "type": "enum",
      "width": 40,
      "enums": [
        {
          "value": "已",
          "label": "已"
        },
        {
          "value": "未",
          "label": "未"
        }
      ]
    },
    "ZN": {
      "label": "子女",
      "type": "num",
      "width": 40,
      "placeholder": "填写数量，没有不填"
    },
    "ZZ": {
      "label": "政治面貌",
      "type": "enum",
      "width": 65,
      "enums": [
        {
          "value": "党员",
          "label": "党员"
        },
        {
          "value": "群众",
          "label": "群众"
        }
      ]
    },
    "HJDZ": {
      "label": "户籍地址",
      "type": "text"
    },
    "HZDZ": {
      "label": "现住地址",
      "type": "text"
    },
    "ZS": {
      "label": "证书",
      "type": "text"
    },
    "GJJZH": {
      "label": "公积金账号"
    },
    "YHKH": {
      "label": "银行卡号"
    },
    "BZ": {
      "label": "备注",
      "type": "text"
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "relations": {
    "xl": {
      "title": "学历表",
      "type": "rDatacenter",
      "kwargs": {
        "path": "/datacenter/xlb",
        "query": {
          "FK": "id"
        },
        "data": {
          "FK": "id"
        }
      }
    },
    "jl": {
      "title": "简历表",
      "type": "rDatacenter",
      "kwargs": {
        "path": "/datacenter/jlb",
        "query": {
          "FK": "id"
        },
        "data": {
          "FK": "id"
        }
      }
    }
  },
  "e_list_status": {
    "0": true,
    "1": []
  },
  "v_list_status": false
}', '1', '', '2022-05-10 16:43:34.600520', '2022-05-14 18:59:59.536774');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (67, '学历表', '{
  "obj": "`T_COMPANY_STAFF_INFO_XL`",
  "config": {
    "selectable": false
  },
  "key_gid": false,
  "key_status": false,
  "columns": {
    "id": "#10#",
    "FK": {
      "label": "信息表ID",
      "type": "remote",
      "enabled": [
        "s",
        "e",
        "a"
      ],
      "null": false,
      "autocomplete": {
        "url": "/datacenter/xxb",
        "key": "staff_info"
      }
    },
    "YX": {
      "label": "毕业院校",
      "null": false
    },
    "ZY": {
      "label": "专业",
      "null": false
    },
    "XZ": {
      "label": "学制",
      "null": false
    },
    "XL": {
      "label": "学历",
      "null": false
    },
    "FJ": {
      "label": "附件",
      "type": "file",
      "tooltip": false,
      "limit": 0
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_list_status": false
}', '1', '', '2022-05-10 16:44:14.114197', '2022-05-14 18:24:35.507592');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (68, '简历表', '{
  "obj": "`T_COMPANY_STAFF_INFO_JL`",
  "config": {
    "selectable": false
  },
  "key_gid": false,
  "key_status": false,
  "columns": {
    "id": "#10#",
    "FK": {
      "label": "信息表ID",
      "type": "remote",
      "enabled": [
        "s",
        "e",
        "a"
      ],
      "null": false,
      "autocomplete": {
        "url": "/datacenter/xxb",
        "key": "staff_info"
      }
    },
    "RZSJ": {
      "label": "任职时间",
      "null": false
    },
    "GS": {
      "label": "公司名称",
      "null": false
    },
    "ZW": {
      "label": "职位",
      "null": false
    },
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "v_list_status": false
}', '1', '', '2022-05-10 16:44:18.152683', '2022-05-14 18:24:35.501571');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (69, '离职表', '{
  "obj": "`V_T_COMPANY_STAFF_INFO_LZ`",
  "table": "`T_COMPANY_STAFF_INFO_LZ`",
  "self": {
    "columns": {
      "status": {
        "enums": [
          {
            "value": "0",
            "label": "待申请"
          },
          {
            "value": "1",
            "label": "主管"
          },
          {
            "value": "2",
            "label": "人事"
          },
          {
            "value": "3",
            "label": "总经理"
          },
          {
            "value": "4",
            "label": "已完成"
          }
        ]
      }
    }
  },
  "config": {
    "clearvform": true
  },
  "sqls": {
    "limit_condition": "#33#"
  },
  "layouts": {
    "sqb": {
      "title": "辞职申请表",
      "showPrint": true,
      "tableStyle": "font-family: SimSun; width: 21cm; margin: auto;font-size: 20px; padding: 0px 25px;",
      "colWidths": [
        150,
        150,
        280,
        150,
        370
      ],
      "trs": [
        {
          "style": "height: 100px;",
          "tds": [
            {
              "class": "txt-center",
              "subStyle": "font-size: 28px;font-weight: bold;margin: 60px 0 30px 0;",
              "label": "辞职申请表",
              "colspan": 5
            }
          ]
        },
        {
          "class": "border border-first",
          "tds": [
            {
              "class": "txt-center border-left-10",
              "label": "申请人",
              "rowspan": 3
            },
            {
              "class": "txt-center",
              "style": "height: 40px;",
              "label": "姓 名"
            },
            {
            },
            {
              "class": "txt-center",
              "label": "部门主管"
            },
            {
              "class": "txt-center border-right-10",
              "keys": "ZG"
            }
          ]
        },
        {
          "class": "border",
          "tds": [
            {
              "class": "txt-center",
              "style": "height: 40px;",
              "label": "部 门"
            },
            {
              "class": "txt-center",
              "keys": "BM"
            },
            {
              "class": "txt-center",
              "label": "职 务"
            },
            {
              "class": "txt-center border-right-10",
              "keys": "ZW"
            }
          ]
        },
        {
          "class": "border",
          "tds": [
            {
              "class": "txt-center",
              "style": "height: 40px;",
              "label": "辞职日期"
            },
            {
              "class": "txt-center",
              "keys": "CZSJ"
            },
            {
              "class": "txt-center",
              "label": "入职日期"
            },
            {
              "class": "txt-center border-right-10",
              "keys": "RZSJ"
            }
          ]
        },
        {
          "class": "border",
          "style": "height: 200px;",
          "tds": [
            {
              "class": "txt-center border-left-10",
              "label": "辞 职<br>原 因"
            },
            {
              "class": "border-last-10",
              "subStyle": "padding:10px",
              "keys": "CZYY",
              "colspan": 4
            }
          ]
        },
        {
          "class": "border",
          "style": "height: 200px;",
          "tds": [
            {
              "class": "txt-center border-left-10",
              "label": "上 级<br>主 管<br>意 见"
            },
            {
              "class": "border-last-10",
              "subStyle": "padding:10px",
              "keys": "ZGYJ",
              "colspan": 4
            }
          ]
        },
        {
          "class": "border",
          "style": "height: 200px;",
          "tds": [
            {
              "class": "txt-center border-left-10",
              "label": "人 事<br>主 管<br>意 见"
            },
            {
              "class": "border-last-10",
              "subStyle": "padding:10px",
              "keys": "RSYJ",
              "colspan": 4
            }
          ]
        },
        {
          "class": "border border-last",
          "style": "height: 200px;",
          "tds": [
            {
              "class": "txt-center border-left-10",
              "label": "总经理<br>意 见"
            },
            {
              "class": "border-last-10",
              "subStyle": "padding:10px",
              "keys": "JLYJ",
              "colspan": 4
            }
          ]
        },
        {
          "tds": [
            {
              "subStyle": "position: absolute; top: 620px; right: 60px;",
              "label": "签字_________"
            },
            {
              "subStyle": "position: absolute; top: 820px; right: 60px;",
              "label": "签字_________"
            },
            {
              "subStyle": "position: absolute; top: 1020px; right: 60px;",
              "label": "签字_________"
            }
          ]
        }
      ]
    },
    "yjqd": {
      "title": "移交清单",
      "showPrint": true,
      "tableStyle": "font-family: SimSun; width: 21cm; margin: auto;font-size: 20px; padding: 0px 25px;",
      "colWidths": [
        100
      ],
      "trs": [
        {
          "tds": [
            {
              "keys": [
                "YJQD"
              ]
            }
          ]
        }
      ]
    }
  },
  "columns": {
    "id": "#10#",
    "gid": "#12#",
    "status": "#13#",
    "FK": {
      "label": "员工档案",
      "type": "remote",
      "enabled": [
        "a",
        "e"
      ],
      "null": false,
      "autocomplete": {
        "url": "/datacenter/xxb",
        "key": "staff_info"
      }
    },
    "XM": {
      "label": "姓名",
      "width": 60,
      "link": "/datacenter/xxb?id={0}",
      "link_keys": [
        "FK"
      ],
      "enabled": [
        "s",
        "a",
        "d"
      ]
    },
    "RZSJ": {
      "label": "入职日期",
      "type": "date",
      "width": 90,
      "enabled": [
        "s",
        "a",
        "d"
      ]
    },
    "ZG": {
      "label": "部门主管",
      "width": 65,
      "null": false
    },
    "BM": {
      "label": "部门",
      "width": 65,
      "null": false
    },
    "ZW": {
      "label": "职务",
      "width": 65,
      "null": false
    },
    "CZSJ": {
      "label": "辞职日期",
      "type": "date",
      "width": 90,
      "null": false
    },
    "CZYY": {
      "label": "辞职原因",
      "type": "text",
      "tooltip": false,
      "null": false
    },
    "ZGYJ": {
      "label": "部门主管意见",
      "type": "text",
      "divider": "部门主管意见",
      "tooltip": false,
      "null": false
    },
    "SJZG": {
      "label": "上级主管",
      "width": 65
    },
    "RSYJ": {
      "label": "人事主管意见",
      "type": "text",
      "divider": "人事主管意见",
      "tooltip": false,
      "null": false
    },
    "RSZG": {
      "label": "人事主管",
      "width": 65
    },
    "JLYJ": {
      "label": "总经理意见",
      "type": "text",
      "divider": "总经理意见",
      "tooltip": false,
      "null": false
    },
    "ZJL": {
      "label": "总经理",
      "width": 65
    },
    "YJQD": {
      "label": "移交清单",
      "type": "richtext",
      "divider": "移交清单",
      "default": "#70#",
      "enabled": [
        "s",
        "e",
        "a",
        "r"
      ]
    },
    "#24#": "#0#",
    "iname": "#14#",
    "idt": "#15#",
    "uname": "#16#",
    "udt": "#17#",
    "vname": "#18#",
    "vdt": "#19#"
  },
  "relations": {
    "sqb": {
      "type": "rLayout",
      "title": "辞职申请表",
      "kwargs": {
        "layout": "sqb"
      }
    },
    "yjqd": {
      "type": "rLayout",
      "title": "移交清单",
      "kwargs": {
        "layout": "yjqd"
      }
    }
  },
  "e_conf": {
    "default_set": false
  },
  "v_conf": {
    "default_set": false
  },
  "v_cmds": [
    {
      "command": "a",
      "label": "确认",
      "tips": "请确认是否继续？"
    },
    {
      "command": "b",
      "label": "驳回",
      "tips": "请确认是否继续？",
      "type": "warning"
    }
  ],
  "commands": {
    "a": "`STATUS` = `STATUS` + 1",
    "b": "`STATUS` = ''0''"
  },
  "e_list_status": {
    "0": [
      "FK",
      "ZG",
      "BM",
      "ZW",
      "CZSJ",
      "CZYY",
      "YJQD"
    ],
    "1": [
      "YJQD"
    ],
    "2": [
      "YJQD"
    ],
    "3": [
      "YJQD"
    ],
    "4": [],
    "5": []
  },
  "v_list_status": {
    "0": [
      "TO",
      "CC"
    ],
    "1": [
      "ZGYJ",
      "TO",
      "CC"
    ],
    "2": [
      "RSYJ",
      "TO",
      "CC"
    ],
    "3": [
      "JLYJ"
    ]
  }
}', '1', '', '2022-05-10 16:44:21.750460', '2022-05-14 19:55:36.746479');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (70, '离职表-移交清单', '<table style="border-collapse:collapse; width:747px" width="744">
	<colgroup>
		<col span="2" style="width:64pt" width="85" />
		<col style="width:52pt" width="69" />
		<col style="width:88pt" width="117" />
		<col style="width:52pt" width="69" />
		<col style="width:88pt" width="117" />
		<col span="2" style="width:76pt" width="101" />
	</colgroup>
	<tbody>
		<tr>
			<td class="xl68" colspan="8" style="border-bottom:1px solid black; height:60px; width:744px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:none; border-left:none"><span style="font-size:27px"><span style="font-weight:700"><span style="color:black"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">移交清单</span></span></span></span></span></span></td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">移交人</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">部门</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">职务</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">日期</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:29px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">移交原因</span></span></span></span></span></span></td>
			<td class="xl65" colspan="7" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">辞职移交</span></span></span></span></span></span></td>
		</tr>
		<tr>
			<td class="xl73" colspan="6" style="border-bottom:1px solid black; height:25px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:.7px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">文件/物品移交项目</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">接收人</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">监交人</span></span></span></span></span></span></td>
		</tr>
		<tr>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; height:24px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">名称</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">数量</span></span></span></span></span></span></td>
			<td class="xl65" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">内容</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl65" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl69" colspan="2" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:1px solid black">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl69" colspan="3" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl70" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl73" colspan="6" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:.7px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">待办事项(工作)移交</span></span></span></span></span></span></td>
			<td class="xl66" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl66" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">NO：1</span></span></span></span></span></span></td>
			<td class="xl65" colspan="5" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">NO：2</span></span></span></span></span></span></td>
			<td class="xl65" colspan="5" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">NO：3</span></span></span></span></span></span></td>
			<td class="xl65" colspan="5" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl65" style="border-bottom:1px solid black; height:30px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">NO：4</span></span></span></span></span></span></td>
			<td class="xl65" colspan="5" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl67" style="border-bottom:1px solid black; height:78px; width:85px; text-align:center; white-space:normal; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle; border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">其 它<br />
			未 尽<br />
			事 宜</span></span></span></span></span></span></td>
			<td class="xl65" colspan="7" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: 1px solid black; border-right: 1px solid black; border-left: none;">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl67" rowspan="2" style="border-bottom:1px solid black; height:79px; width:85px; text-align:center; white-space:normal; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle; border-top:none; border-right:1px solid black; border-left:1px solid black"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">各部门<br />
			意 见</span></span></span></span></span></span></td>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">总经理/副总经理</span></span></span></span></span></span></td>
			<td class="xl65" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">财务部</span></span></span></span></span></span></td>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">行政人事部</span></span></span></span></span></span></td>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none"><span style="font-size:16px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">部门主管</span></span></span></span></span></span></td>
		</tr>
		<tr>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; height:58px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl66" style="border-bottom: 1px solid black; padding-top: 1px; padding-right: 1px; padding-left: 1px; vertical-align: middle; white-space: nowrap; border-top: none; border-right: 1px solid black; border-left: none; text-align: center;">&nbsp;</td>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
			<td class="xl65" colspan="2" style="border-bottom:1px solid black; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:1px solid black; border-left:none">&nbsp;</td>
		</tr>
		<tr>
			<td class="xl71" colspan="8" rowspan="2" style="border-bottom:none; height:38px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:1px solid black; border-right:none; border-left:none"><span style="font-size:15px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">　</span></span></span></span></span></span></td>
		</tr>
		<tr>
		</tr>
		<tr>
			<td class="xl72" colspan="8" style="border-bottom:none; height:19px; text-align:center; padding-top:1px; padding-right:1px; padding-left:1px; vertical-align:middle;  border-top:none; border-right:none; border-left:none"><span style="font-size:15px"><span style="color:black"><span style="font-weight:400"><span style="font-style:normal"><span style="text-decoration:none"><span style="font-family:等线">移交人：__________&nbsp;&nbsp;&nbsp; 监交人：__________&nbsp;&nbsp; 接收人：__________</span></span></span></span></span></span></td>
		</tr>
	</tbody>
</table>', '8', '', '2022-05-10 16:44:25.176317', '2022-05-14 13:46:15.459536');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (71, '财务管理-登记表', '{}', '1', '', '2022-05-10 16:44:28.687429', '2022-05-14 09:18:13.251540');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (72, '财务管理-付款单', '{}', '1', '', '2022-05-10 16:49:45.444924', '2022-05-14 09:18:13.248536');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (73, '财务管理-报账单', '{}', '1', '', '2022-05-14 09:14:00.963399', '2022-05-14 09:18:13.244521');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (74, '财务管理-借款单', '{}', '1', '', '2022-05-14 09:14:04.081635', '2022-05-14 09:18:13.239508');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (75, '财务管理-差旅费', '{}', '1', '', '2022-05-14 09:14:05.227190', '2022-05-14 09:18:13.233491');
INSERT INTO aioa.base_config (id, name, conf, type, remark, edt, udt) VALUES (76, '财务管理-仓储费', '{}', '1', '', '2022-05-14 09:14:07.330212', '2022-05-14 09:18:13.226512');

INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (1, '/test', '测试', 1, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (2, '/datacenter/feedback', '系统反馈', 2, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (3, '/datacenter/files', '系统管理/文件管理', 3, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (4, '/datacenter/event', '系统管理/事件管理', 4, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (5, '/system/logs', '系统管理/日志中心', 5, '{ "keepAlive": true }', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (6, '/system/perms', '系统管理/权限管理', 6, '{ "keepAlive": true }', '/system/permsquery', 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (7, '/system/onliners', '系统管理/在线账号', 7, '{ "keepAlive": true }', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (8, '/datacenter/staff', '通讯录', 100, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (9, '/datacenter/calendar', '日常工作/日程管理', 100, '{}', '/base/,/base/home,/base/remote,/base/touch,/base/upload,/base/printed,/base/menu,/base/calendar,/base/userroles,/base/userconfs,/base/login,/base/logout', 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (10, '/datacenter/todolist', '日常工作/待办事项', 100, '{}', '/chat/heartbeat,/chat/username,/chat/usermail,/chat/sendmail,/chat/download,/chat/userinfo', 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (11, '/datacenter/notice', '公司管理/通知', 200, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (12, '/datacenter/jjr', '人事管理/考勤管理/节假日', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (13, '/datacenter/qjt', '人事管理/考勤管理/请假条', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (14, '/datacenter/jbd', '人事管理/考勤管理/加班单', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (15, '/datacenter/txd', '人事管理/考勤管理/调休单', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (16, '/datacenter/ldk', '人事管理/考勤管理/漏打卡', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (17, '/datacenter/cmt', '人事管理/考勤管理/出门条', 300, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (18, '/datacenter/xxb', '人事管理/员工档案/信息表', 400, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (19, '/datacenter/xlb', '人事管理/员工档案/*学历表', 400, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (20, '/datacenter/jlb', '人事管理/员工档案/*简历表', 400, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (21, '/datacenter/lzb', '人事管理/员工档案/离职表', 400, '{}', null, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (22, '/datacenter/djb', '财务管理/登记表', 500, '{}', null, 1, '2022-05-10 15:34:16.101394', '2022-05-10 15:48:32.354435');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (23, '/datacenter/fkd', '财务管理/付款单', 500, '{}', null, 1, '2022-05-10 15:34:36.413369', '2022-05-10 15:48:32.361456');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (24, '/datacenter/bzd', '财务管理/报账单', 500, '{}', null, 1, '2022-05-10 15:34:55.409267', '2022-05-10 15:48:32.367472');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (25, '/datacenter/jkd', '财务管理/借款单', 500, '{}', null, 1, '2022-05-10 15:35:05.831399', '2022-05-10 15:48:32.371483');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (26, '/datacenter/clf', '财务管理/明细表/差旅费', 500, '{}', null, 1, '2022-05-10 16:07:20.947922', '2022-05-10 16:08:05.380190');
INSERT INTO aioa.base_menu (id, path, name, sort, meta, relations, enable, edt, udt) VALUES (27, '/datacenter/ccf', '财务管理/明细表/仓储费', 500, '{}', null, 1, '2022-05-10 16:48:34.801946', '2022-05-10 16:48:53.914054');

INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (1, '测试', 0, 100, 1, '2022-05-10 16:03:40.044634', '2022-05-10 16:34:19.024926', 41, 1, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (2, '系统反馈', 0, 100, 1, '2022-05-10 16:03:40.049641', '2022-05-10 16:34:19.021918', 42, 2, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (3, '文件管理', 0, 100, 1, '2022-05-10 16:03:40.053678', '2022-05-10 16:34:19.017906', 43, 3, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (4, '事件管理', 0, 100, 1, '2022-05-10 16:03:40.055657', '2022-05-10 16:34:19.013896', 44, 4, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (5, '日志中心', 0, 100, 1, '2022-05-10 16:03:40.058665', '2022-05-10 16:03:40.058665', 1, 5, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (6, '权限管理', 0, 100, 1, '2022-05-10 16:03:40.063678', '2022-05-10 16:03:40.063678', 1, 6, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (7, '在线账号', 0, 100, 1, '2022-05-10 16:03:40.066687', '2022-05-10 16:03:40.066687', 1, 7, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (8, '通讯录', 0, 100, 1, '2022-05-10 16:03:40.068692', '2022-05-10 16:34:19.008882', 45, 8, 46, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (9, 'xx集团', 10, 100, 1, '2022-05-10 16:04:11.137764', '2022-05-10 16:34:19.004872', 45, 8, 48, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (10, 'xx科技', 20, 100, 1, '2022-05-10 16:04:19.111064', '2022-05-10 16:34:18.998884', 45, 8, 50, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (11, '预留1', 30, 100, 1, '2022-05-10 16:05:16.692074', '2022-05-14 09:22:43.736718', 45, 8, 52, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (12, '预留2', 40, 100, 1, '2022-05-10 16:05:16.697123', '2022-05-14 09:24:44.463040', 45, 8, 54, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (13, '日程管理', 0, 100, 1, '2022-05-10 16:05:16.701100', '2022-05-14 09:25:34.442086', 56, 9, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (14, '待办事项', 0, 100, 1, '2022-05-10 16:05:16.707115', '2022-05-14 09:25:34.435048', 57, 10, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (15, '通知', 0, 100, 1, '2022-05-10 16:05:16.711124', '2022-05-14 20:01:11.920923', 58, 11, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (16, '节假日', 0, 100, 1, '2022-05-10 16:05:16.715135', '2022-05-14 09:28:36.580856', 60, 12, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (17, '请假条', 0, 100, 1, '2022-05-10 16:05:16.719147', '2022-05-14 09:28:42.903855', 61, 13, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (18, '加班单', 0, 100, 1, '2022-05-10 16:05:16.723157', '2022-05-14 09:28:42.898842', 62, 14, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (19, '调休单', 0, 100, 1, '2022-05-10 16:05:16.727194', '2022-05-14 09:28:42.894831', 63, 15, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (20, '漏打卡', 0, 100, 1, '2022-05-10 16:05:16.731179', '2022-05-14 09:28:42.890824', 64, 16, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (21, '出门条', 0, 100, 1, '2022-05-10 16:05:16.735188', '2022-05-14 09:28:42.882472', 65, 17, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (22, '信息表', 0, 100, 1, '2022-05-10 16:05:16.740203', '2022-05-14 09:31:03.291642', 66, 18, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (23, '学历表', 0, 100, 1, '2022-05-10 16:05:16.744227', '2022-05-14 09:31:03.286630', 67, 19, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (24, '简历表', 0, 100, 1, '2022-05-10 16:05:54.783166', '2022-05-14 09:31:03.267578', 68, 20, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (25, '离职表', 0, 100, 1, '2022-05-10 16:06:25.699087', '2022-05-14 09:31:12.664900', 69, 21, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (26, '财务管理-登记表', 0, 100, 1, '2022-05-10 16:06:25.704099', '2022-05-14 09:31:12.659886', 71, 22, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (27, '财务管理-付款单', 0, 100, 1, '2022-05-10 16:06:25.708108', '2022-05-14 09:31:12.655876', 72, 23, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (28, '财务管理-报账单', 0, 100, 1, '2022-05-10 16:09:17.542093', '2022-05-14 09:31:12.651865', 73, 24, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (29, '财务管理-借款单', 0, 100, 1, '2022-05-10 16:49:31.880780', '2022-05-14 09:31:12.644846', 74, 25, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (30, '财务管理-差旅费', 0, 100, 1, '2022-05-14 09:21:49.117820', '2022-05-14 09:31:12.640835', 75, 26, 1, 1);
INSERT INTO aioa.base_module (id, label, value, sort, enable, edt, udt, base_config_id, menu_id, over_config_id, spec_config_id) VALUES (31, '财务管理-仓储费', 0, 100, 1, '2022-05-14 09:21:53.427008', '2022-05-14 09:31:12.634831', 76, 27, 1, 1);

INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (1, '管理员', 0, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (2, '临时', 0, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (3, '基础', 0, 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (4, 'xx集团-董事会-董事长', 1, 1, '2022-05-14 10:09:17.125819', '2022-05-14 10:09:17.125819');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (5, 'xx集团-董事会-副董事长', 1, 1, '2022-05-14 10:09:30.140776', '2022-05-14 10:09:30.140776');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (6, 'xx集团-董事会-秘书', 1, 1, '2022-05-14 10:09:39.575684', '2022-05-14 10:09:39.575684');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (7, 'xx集团-管理部-总经理', 1, 1, '2022-05-14 10:09:56.598761', '2022-05-14 10:09:56.598761');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (8, 'xx集团-管理部-副总经理', 1, 1, '2022-05-14 10:10:11.005422', '2022-05-14 10:10:11.005422');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (9, 'xx集团-管理部-秘书', 1, 1, '2022-05-14 10:10:21.316110', '2022-05-14 10:10:21.316110');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (10, 'xx集团-财务部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (11, 'xx集团-财务部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (12, 'xx集团-财务部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (13, 'xx集团-财务部-会计', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (14, 'xx集团-财务部-出纳', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (15, 'xx集团-财务部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (16, 'xx集团-行政部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (17, 'xx集团-行政部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (18, 'xx集团-行政部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (19, 'xx集团-行政部-行政', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (20, 'xx集团-行政部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (21, 'xx集团-人事部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (22, 'xx集团-人事部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (23, 'xx集团-人事部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (24, 'xx集团-人事部-人事', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (25, 'xx集团-人事部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (26, 'xx集团-销售部-总监', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (27, 'xx集团-销售部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (28, 'xx集团-销售部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (29, 'xx集团-销售部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (30, 'xx集团-信息部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (31, 'xx集团-信息部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (32, 'xx科技-管理部-总经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (33, 'xx科技-管理部-副总经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (34, 'xx科技-管理部-秘书', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (35, 'xx科技-财务部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (36, 'xx科技-财务部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (37, 'xx科技-财务部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (38, 'xx科技-财务部-会计', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (39, 'xx科技-财务部-出纳', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (40, 'xx科技-财务部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (41, 'xx科技-行政部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (42, 'xx科技-行政部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (43, 'xx科技-行政部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (44, 'xx科技-行政部-行政', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (45, 'xx科技-行政部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (46, 'xx科技-人事部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (47, 'xx科技-人事部-主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (48, 'xx科技-人事部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (49, 'xx科技-人事部-人事', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (50, 'xx科技-人事部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (51, 'xx科技-项目中心-研发部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (52, 'xx科技-项目中心-研发部-一组主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (53, 'xx科技-项目中心-研发部-二组主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (54, 'xx科技-项目中心-研发部-三组主管', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (55, 'xx科技-项目中心-研发部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (56, 'xx科技-项目中心-运维部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (57, 'xx科技-项目中心-运维部-助理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (58, 'xx科技-项目中心-运维部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (59, 'xx科技-信息部-经理', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');
INSERT INTO aioa.base_role (id, name, is_post, enable, edt, udt) VALUES (60, 'xx科技-信息部-员工', 1, 1, '2022-05-13 19:21:21', '2022-05-13 19:21:21');

INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (1, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 5, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (2, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 6, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (3, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 7, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (4, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 1, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (5, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 2, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (6, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 3, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (7, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 4, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (8, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 8, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (9, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 9, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (10, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 10, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (11, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 11, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (12, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 12, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (13, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 13, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (14, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 14, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (15, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 15, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (16, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 16, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (17, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 17, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (18, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 18, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (19, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 19, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (20, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 20, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (21, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 21, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (22, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 22, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (23, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 23, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (24, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 24, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (25, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 25, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (26, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 26, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (27, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 27, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (28, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 28, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (29, 1, '2022-05-10 02:04:04', '2022-05-10 02:04:04', 29, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (30, 1, '2022-05-14 10:24:09.738977', '2022-05-14 10:24:09.738977', 30, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (31, 1, '2022-05-14 10:24:09.738977', '2022-05-14 10:24:09.738977', 31, 2, 1);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (32, 1, '2022-05-14 10:25:02.097922', '2022-05-14 10:25:02.097922', 2, 7, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (33, 1, '2022-05-14 10:25:12.963056', '2022-05-14 10:25:12.963056', 8, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (34, 1, '2022-05-14 10:25:21.428872', '2022-05-14 10:25:21.428872', 13, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (35, 1, '2022-05-14 10:25:21.428872', '2022-05-14 10:25:21.428872', 14, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (36, 1, '2022-05-14 10:25:25.722065', '2022-05-14 10:25:25.722065', 15, 59, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (37, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 17, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (38, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 18, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (39, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 19, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (40, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 20, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (41, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 21, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (42, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 27, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (43, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 28, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (44, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 29, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (45, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 30, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (46, 1, '2022-05-14 10:26:04.859377', '2022-05-14 10:26:04.859377', 31, 2, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (47, 1, '2022-05-14 10:26:10.161543', '2022-05-14 10:26:10.161543', 26, 8, 3);
INSERT INTO aioa.base_roleperm (id, enable, edt, udt, module_id, perm_config_id, role_id) VALUES (48, 1, '2022-05-14 10:26:16.075647', '2022-05-14 10:26:16.075647', 25, 2, 3);

INSERT INTO aioa.base_userconf (id, user, conf, remark, edt, udt) VALUES (1, 'system', '{}', null, '2022-05-06 07:54:08', '2022-05-06 07:54:08');

INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (1, 'admin', 1, '2022-05-06 07:54:08', '2022-05-06 07:54:08', 1);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (2, '100001', 1, '2022-05-13 18:03:17', '2022-05-13 18:03:17', 3);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (3, '100002', 1, '2022-05-13 18:03:21', '2022-05-13 18:03:21', 3);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (4, '100003', 1, '2022-05-13 18:03:25', '2022-05-13 18:03:25', 3);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (5, '100004', 1, '2022-05-13 18:03:48', '2022-05-13 18:03:48', 3);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (6, '100004', 1, '2022-05-13 18:03:48', '2022-05-13 18:03:48', 1);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (8, '100001', 1, '2022-05-13 19:27:42', '2022-05-13 19:27:42', 1);
INSERT INTO aioa.base_userrole (id, user, enable, edt, udt, role_id) VALUES (9, '100001', 1, '2022-05-13 19:27:42', '2022-05-13 19:27:42', 4);

INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (1, 0, '1', '2022-05-13 05:06:35', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '元旦节', '2022-01-01 00:00:00', '2022-01-03 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (2, 0, '1', '2022-05-13 05:07:24', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '上班', '2022-01-29 00:00:00', '2022-01-30 23:59:59', '1', null, null, null, '春节调休');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (3, 0, '1', '2022-05-13 05:07:53', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '春节', '2022-01-31 00:00:00', '2022-02-06 23:59:59', '0', null, null, null, '春节快乐');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (4, 0, '1', '2022-05-13 05:08:57', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '上班', '2022-04-02 00:00:00', '2022-04-02 23:59:59', '1', null, null, null, '清明节调休');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (5, 0, '1', '2022-05-13 05:09:21', '2022-05-13 05:12:29', '2022-05-13 05:13:37', 'admin', 'admin', 'admin', '清明节', '2022-04-03 00:00:00', '2022-04-05 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (6, 0, '1', '2022-05-13 05:09:51', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '上班', '2022-04-24 00:00:00', '2022-04-24 23:59:59', '1', null, null, null, '劳动节调休');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (7, 0, '1', '2022-05-13 05:10:16', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '劳动节', '2022-05-01 00:00:00', '2022-05-04 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (8, 0, '1', '2022-05-13 05:10:47', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '上班', '2022-05-07 00:00:00', '2022-05-07 23:59:59', '1', null, null, null, '劳动节调休');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (9, 0, '1', '2022-05-13 05:11:06', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '端午节', '2022-06-03 00:00:00', '2022-06-05 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (10, 0, '1', '2022-05-13 05:11:25', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '中秋节', '2022-09-10 00:00:00', '2022-09-12 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (11, 0, '1', '2022-05-13 05:11:46', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '国庆节', '2022-10-01 00:00:00', '2022-10-07 23:59:59', '0', null, null, null, null);
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (12, 0, '1', '2022-05-13 05:12:10', null, '2022-05-13 05:13:37', 'admin', null, 'admin', '上班', '2022-10-08 00:00:00', '2022-10-09 23:59:59', '1', null, null, null, '国庆节调休');
INSERT INTO aioa.T_COMPANY_CALENDAR (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, NAME, BEGIN_DT, END_DT, CLS, WARN_DAY, WARN_TIMES, `GROUPS`, REMARK) VALUES (13, 0, '1', '2022-05-13 05:50:37', null, '2022-05-13 05:50:40', 'admin', null, 'admin', '测试', '2022-05-13 00:00:00', '2022-05-13 23:59:59', '3', null, 0, null, null);

INSERT INTO aioa.T_COMPANY_STAFF (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, STAFF_ID, POSITION, LEADERS, FULL_NAME, ABBR_NAME, EMAIL, TEL, MP, ROLES, REMARK, IP) VALUES (1, 10, '1', '2022-05-13 04:49:52', '2022-05-13 19:27:53', '2022-05-13 17:47:26', 'admin', 'admin', 'admin', '100001', '董事会 / 董事长', null, 'Dawn', 'Dawn', null, null, null, '3 , 1 , 4', null, null);
INSERT INTO aioa.T_COMPANY_STAFF (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, STAFF_ID, POSITION, LEADERS, FULL_NAME, ABBR_NAME, EMAIL, TEL, MP, ROLES, REMARK, IP) VALUES (2, 10, '1', '2022-05-13 04:54:25', '2022-05-14 06:10:26', '2022-05-13 17:56:14', 'admin', 'admin', 'admin', '100002', '管理部 / 助理', '100001', '陈一', '陈一', null, null, null, '3', null, null);
INSERT INTO aioa.T_COMPANY_STAFF (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, STAFF_ID, POSITION, LEADERS, FULL_NAME, ABBR_NAME, EMAIL, TEL, MP, ROLES, REMARK, IP) VALUES (3, 10, '1', '2022-05-13 04:54:46', '2022-05-14 06:10:35', '2022-05-13 17:56:14', 'admin', 'admin', 'admin', '100003', '管理部 / 员工', '100002', '陈二', '陈二', null, null, null, '3', null, '127.0.0.1');
INSERT INTO aioa.T_COMPANY_STAFF (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, STAFF_ID, POSITION, LEADERS, FULL_NAME, ABBR_NAME, EMAIL, TEL, MP, ROLES, REMARK, IP) VALUES (4, 10, '1', '2022-05-13 17:57:02', '2022-05-14 06:10:40', '2022-05-13 18:03:48', 'admin', 'admin', 'admin', '100004', '财务部 / 经理', '100003', '陈三', '陈三', null, null, null, '3 , 1', null, '127.0.0.1');

INSERT INTO aioa.T_COMPANY_STAFF_RELATION (ID, GID, STATUS, I_NAME, U_NAME, V_NAME, I_DT, U_DT, V_DT, STAFF_ID, STAFF_ID_L) VALUES (1, 0, '1', 'admin', null, null, '2022-05-14 06:10:26', null, null, '100002', '100001');
INSERT INTO aioa.T_COMPANY_STAFF_RELATION (ID, GID, STATUS, I_NAME, U_NAME, V_NAME, I_DT, U_DT, V_DT, STAFF_ID, STAFF_ID_L) VALUES (2, 0, '1', 'admin', null, null, '2022-05-14 06:10:35', null, null, '100003', '100002');
INSERT INTO aioa.T_COMPANY_STAFF_RELATION (ID, GID, STATUS, I_NAME, U_NAME, V_NAME, I_DT, U_DT, V_DT, STAFF_ID, STAFF_ID_L) VALUES (3, 0, '1', 'admin', null, null, '2022-05-14 06:10:40', null, null, '100004', '100003');

INSERT INTO aioa.T_COMPANY_STAFF_INFO (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, BH, GH, GS, BM, XM, SJHM, SFZH, YHKH, GJJZH, JZGW, RZSJ, HTYXQ, ZZ, JG, HJ, HY, ZN, HJDZ, HZDZ, ZS, BZ, SX) VALUES (1, 0, '0', '2022-05-14 03:57:05', null, null, 'admin', null, null, 1, '100004', 'xx集团', null, 'xx', null, '310000199211111111', null, null, null, '2022-05-14', null, null, null, null, null, null, null, null, null, null, null);

INSERT INTO aioa.T_COMPANY_STAFF_INFO_JL (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, FK, RZSJ, GS, ZW) VALUES (1, 0, '0', '2022-05-14 03:58:38', null, null, 'admin', null, null, 1, '2015~2019', 'xx', 'xx');

INSERT INTO aioa.T_COMPANY_STAFF_INFO_XL (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, FK, YX, ZY, XZ, XL, FJ) VALUES (1, 0, '0', '2022-05-14 03:57:43', null, null, 'admin', null, null, 1, '复旦大学', '电子工程', '4', '本科', null);
INSERT INTO aioa.T_COMPANY_STAFF_INFO_XL (ID, GID, STATUS, I_DT, U_DT, V_DT, I_NAME, U_NAME, V_NAME, FK, YX, ZY, XZ, XL, FJ) VALUES (2, 0, '0', '2022-05-14 03:58:09', null, null, 'admin', null, null, 1, '交通大学', '软件工程', '4', '硕士', null);
