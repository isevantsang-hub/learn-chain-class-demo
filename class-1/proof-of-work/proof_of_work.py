import hashlib

def proof_of_work(data, difficulty):
    """"
    执行工作量证明，返回满足难度的 nonce 和哈希值
    data: 原始数据字符串
    difficulty: 要求哈
    希值开头 '0' 的个数（十六进制）
    """
    target_prefix = "0" * difficulty
    nonce = 0
    while True:
        # 组合数据与 nonce 并计算 SHA256
        text = f"{data}{nonce}".encode()
        hash_result = hashlib.sha256(text).hexdigest()
        
        if hash_result.startswith(target_prefix):
            return nonce, hash_result
        nonce += 1