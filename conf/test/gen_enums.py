import json

string = """
总经理
副总经理
经理
主管
总监
助理
员工
行政
人事
会计
出纳
内务
商务
采购
仓管
发展
理化
数据
信息
仪器
质量
司炉
维修
注册
注册专员
注册总管
注册组长
DMF收集
资料收集
一区经理
一区内务
一区推广
二区经理
二区内务
二区推广
三区经理
三区内务
三区推广
工程师
工艺员
仓管员
操作员
研究员
养护员
微生物
纯化水
生产QA
文件QA
质检QA
"""


def main():
    enums = [{"value": item, "label": item} for item in string.split() if item]
    print(json.dumps(enums, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
