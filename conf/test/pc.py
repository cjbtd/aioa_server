def permutation_combination(chars: list[str], lengths: list[int] = None) -> None:
    """
    给定一组字符串，计算出所有排列组合

    :param chars: List[Str], 待计算的字符串列表，不能重复
    :param lengths: List[Int], 允许生成的字符串长度列表，默认是所有可能的长度
    :return List
    """
    _len = len(chars)
    assert _len == len(set(chars)), '给定的列表不能包含重复数据：{}'.format(chars)

    # 默认包含所有可能长度
    if lengths is None:
        lengths = range(1, _len + 1)
    else:
        pass

    # 所有结果
    result = set()
    for length in lengths:
        # 某个长度的

        tmp = [c for c in chars]
        for i in range(length):
            for t in tmp:
                if len(t) == length:
                    result.add(t)
                else:
                    for c in chars:
                        if chars.index(c) > chars.index(t[-1]):
                            tmp.append(t + c)

    print(len(result))
    for r in result:
        if ('d' in r or 'r' in r) and 'a' not in r:
            pass
        else:
            print(r)


permutation_combination(['s', 'e', 'v', 'a', 'd', 'r'])
