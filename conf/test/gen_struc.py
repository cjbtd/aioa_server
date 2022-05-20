import json

string = """
管理员
临时
基础
xx公司-管理部
xx公司-财务部
xx公司-行政部
xx公司-人事部

xx公司-管理部-总经理
xx公司-财务部-经理
xx公司-行政部-经理
xx公司-人事部-经理

xx公司-管理部-助理
xx公司-财务部-助理
xx公司-行政部-助理
xx公司-人事部-助理

xx公司-管理部-员工
xx公司-财务部-员工
xx公司-行政部-员工
xx公司-人事部-员工

xx公司-行政部-主管
xx公司-人事部-主管
xx公司-财务部-主管
"""


def main():
    enums = []

    for item in string.split():
        names = item.split('-')
        children = enums

        for idx, name in enumerate(names):
            if not name.strip():
                continue
            else:
                pass

            is_not_exists = True

            sub_enum = {}

            for enum in children:
                if enum['label'] == name:
                    sub_enum = enum
                    if idx < len(names) - 1:
                        if sub_enum.get('children') is None:
                            sub_enum.update({'children': []})
                        else:
                            pass
                    else:
                        pass
                    is_not_exists = False
                    break
                else:
                    pass

            if is_not_exists:
                sub_enum = {'value': name, 'label': name}
                if idx < len(names) - 1:
                    sub_enum.update({'children': []})

                children.append(sub_enum)
            else:
                pass

            children = sub_enum.get('children', [])

    print(json.dumps(enums, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
