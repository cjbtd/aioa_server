from typing import Any, Iterable
import re

sql_all_modules = """
SELECT mo.`id`
      ,`name`
      ,`label`
      ,`base_config_id`
      ,`over_config_id`
      ,`spec_config_id`
  FROM `base_menu` me
       INNER JOIN 
       `base_module` mo
           ON mo.`menu_id` = me.`id`
 WHERE me.`enable` = 1
       AND mo.`enable` = 1
ORDER BY me.`sort`, me.`id`, mo.`sort`, mo.`id`
"""
sql_get_modules = """
SELECT `user`
      ,`module_sort`
      ,`module_id`
      ,`menu_sort`
      ,`menu_id`
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
  FROM V_USER_MODULES 
 WHERE {} 
ORDER BY 4,5,2,3
"""
sql_conf_relations = """
SELECT DISTINCT `base_config_id`,`over_config_id`,`spec_config_id`,`perm_config_id`
  FROM V_USER_MODULES 
 WHERE `base_config_id` IN ({0}) 
       OR `over_config_id` IN ({0}) 
       OR `spec_config_id` IN ({0}) 
       OR `perm_config_id` IN ({0}) 
"""
sql_search_role = """
SELECT `name` 
  FROM `base_role` r
 WHERE `enable` = 1 
       AND `id` IN (
           SELECT `role_id` 
             FROM `base_roleperm` rp
            WHERE `enable` = 1 
                  AND `module_id` IN (
                      SELECT `id` 
                        FROM `base_module` mo
                       WHERE `label` LIKE {0}
                             OR EXISTS (
                                 SELECT 1
                                   FROM `base_menu` me
                                  WHERE me.`id` = mo.`menu_id`
                                        AND `enable` = 1 
                                        AND `name` LIKE {0}
                             )
                  )
       )
"""

sql_get_calendar_events = """
SELECT `ID`
      ,`NAME`
      ,`BEGIN_DT`
      ,`END_DT`
      ,`CLS`
      ,`REMARK` 
  FROM `T_COMPANY_CALENDAR` 
 WHERE `STATUS` = '1'
       AND `BEGIN_DT` <= ADDDATE(CAST({0} AS DATETIME), 42)
       AND `END_DT` >= CAST({0} AS DATETIME)
       AND (`I_NAME` = {1} OR `CLS` IN ('0', '1'))
       AND (IFNULL(`GROUPS`, '') = '' OR `GROUPS` LIKE CONCAT('%', SUBSTRING({1}, 1, 2), '%'));
"""

sql_get_user_info = """
SELECT a.`username`
      ,a.`last_login`
      ,a.`last_name` AS agent
      ,a.`email` AS ips
      ,a.`date_joined`
      ,b.`FULL_NAME`
      ,b.`POSITION`
      ,b.`LEADERS`
      ,b.`ABBR_NAME`
      ,b.`EMAIL`
      ,b.`TEL`
      ,b.`MP`
      ,b.`ROLES`
      ,b.`REMARK`
      ,b.`IP`
      ,b.`ID`
      ,b.`GID`
  FROM `auth_user` a
       LEFT JOIN
       `T_COMPANY_STAFF` b
           ON a.`username` = b.`STAFF_ID`
 WHERE a.`is_active` = 1
ORDER BY `username`
"""
sql_update_user_info = """
UPDATE `auth_user` 
   SET `last_name` = {1}
      ,`email` = {2}
 WHERE `username` = {0};

UPDATE `T_COMPANY_STAFF`
   SET `IP` = {3}
 WHERE `STAFF_ID` = {0};
"""
sql_get_self_info = """
SELECT `FULL_NAME`
      ,`EMAIL`
      ,`TEL`
      ,`MP`
  FROM `T_COMPANY_STAFF`
 WHERE `STAFF_ID` = {0};
"""
sql_update_self_info = """
UPDATE `T_COMPANY_STAFF`
   SET `EMAIL` = {1}
      ,`TEL` = {2}
      ,`MP` = {3}
 WHERE `STAFF_ID` = {0};
"""

sql_sum = """
SELECT CAST(SUM({1}) AS DECIMAL(20,{0})) AS __sum
  FROM {2}
 WHERE {3}
"""
sql_unique = """
;WITH tmp AS (
SELECT DISTINCT {}
  FROM {}
 WHERE {}
)

SELECT {} FROM tmp {}
"""
sql_del = """
DELETE {} 
 WHERE {}
"""
sql_cte = """
WITH cte_oa AS (
{}
)

{}
"""
sql_attendance = """
SELECT `GH`
      ,`XM`
  FROM `T_COMPANY_STAFF_INFO`
 WHERE `GS` = {0}
       AND `STATUS` = '0'
ORDER BY `SX`,`BM`,`RZSJ`;

SELECT `I_NAME`
      ,`CLS`
      ,`BEGIN_DT`
      ,`END_DT`
      ,`TOTAL` = `FN_CALC_WORK_MINUTE`(
          CASE WHEN `BEGIN_DT` < {1} THEN {1} ELSE `BEGIN_DT` END,
          CASE WHEN `END_DT` > {2} THEN {2} ELSE `END_DT` END,
          1)
  FROM `T_COMPANY_LEAVE_INFO`
 WHERE `STATUS` = '2'
       AND `BEGIN_DT` <= {2} 
       AND `END_DT` >= {1};

SELECT `I_NAME`
      ,`ED`
  FROM `T_COMPANY_FORGET_PUNCH` 
 WHERE `STATUS` = '2'
       AND `ED` BETWEEN {1} AND {2};

SELECT `BEGIN_DT`
      ,`END_DT`
      ,`CLS`
  FROM `T_COMPANY_CALENDAR`
 WHERE `STATUS` = '1'
       AND `CLS` IN ('0', '1')
       AND `BEGIN_DT` <= {2} 
       AND `END_DT` >= {1};
"""

sql_get_contacts = """
SELECT `ID`
      ,`POSITION`
      ,`FULL_NAME` 
  FROM `T_COMPANY_STAFF` 
 WHERE `STATUS` = '1'
       AND `GID` = {}
"""
sql_update_contacts = """
UPDATE `T_COMPANY_STAFF`
   SET `POSITION` = {}
 WHERE `ID` IN ({})
"""

sql_common_select = """
SELECT {}
  FROM {}
 WHERE {}
{}
{}
"""
sql_common_insert = """
INSERT INTO {}({}) 
VALUES ({})
"""
sql_common_update = """
UPDATE {2} {0}
   SET {1}
 WHERE {3}
"""

sql_all = "*"
sql_wrap = "`{}`"
sql_count = "COUNT(*) AS __count"
sql_od = "ORDER BY {}"
sql_asc = "ASC"
sql_desc = "DESC"
sql_isnull = "IFNULL({}, {})"
sql_getdate = "CURRENT_TIMESTAMP"
sql_between = "{} BETWEEN {} AND {}"
sql_pagination = "LIMIT {}, {}"
sql_quoted_identifier = "'"
sql_last_insert_id = "SELECT LAST_INSERT_ID()"

sql_set = "{} = {}"
sql_eq = "{} = {}"
sql_lt = "{} < {}"
sql_lte = "{} <= {}"
sql_gt = "{} > {}"
sql_gte = "{} >= {}"
sql_in = "{} IN ({})"
sql_or = " OR "
sql_or_n = "\r\n       OR "
sql_and = " AND "
sql_and_n = "\r\n       AND "
sql_link = ", "
sql_link_n = "\r\n      ,"
sql_like = "{0} {1}LIKE {2} ESCAPE " + "{0}\\\\{0}".format(sql_quoted_identifier)

wrap_except_dict = {
    None: "",
    True: "1",
    False: "0",
    "NULL": "NULL",
    sql_getdate: sql_getdate
}


def escape(chars, like=False):
    """
    True     -> 1
    False    -> 0
    None     -> ''
    'NULL'   -> NULL
    sql func -> sql func

    :param chars: Any
    :param like: Bool, If true build like query
    :return:
    """
    if chars in wrap_except_dict:
        return wrap_except_dict[chars]

    if not isinstance(chars, str):
        chars = str(chars)

    value = chars.strip().replace(sql_quoted_identifier, sql_quoted_identifier * 2)

    if like:
        prefix = "" if value.startswith("^") else "%"
        suffix = "" if value.endswith("$") else "%"
        value = value.lstrip("^").rstrip("$")
        value = re.sub(r"([\^_\[\]%])", r"\\\1", value)
        value = value.replace(" ", "%")
        value = "{}{}{}".format(prefix, value, suffix)
    else:
        pass
    return "N{0}{1}{0}".format(sql_quoted_identifier, value)


def vals_to_strs(vals: Iterable, filters=None, link=","):
    """
    Concatenate the list of values into SQL value strings

    :param vals: iterable
    :param filters: list
    :param link: string
    :return: string
    """
    if isinstance(vals, Iterable) is False:
        return ""

    if filters is None:
        filters = []
    else:
        pass

    res = set()
    for val in vals:
        if val in filters:
            continue
        else:
            pass

        if isinstance(val, int) or isinstance(val, float):
            val = str(val)
        else:
            val = escape(val)

        res.add(val)
    return link.join(res)


def null_to_val(val: Any, default: str = "", null_set: set = None) -> Any:
    """
    [None、'NULL'、''] to default

    :param val:
    :param default:
    :param null_set:
    :return:
    """
    if null_set is None:
        null_set = {"NULL", None, "", "null", "undefined"}
    else:
        pass

    return default if val in null_set else val
