
import time
import pytest
from cus_proof_of_work import cus_proof_of_work
from cus_proof_of_work import cus_proof_of_work_1

# 参数化测试：分别测试难度 4、5、6
@pytest.mark.parametrize("difficulty", [4, 5, 6])
def test_cus_pow_performance(difficulty):
    data = "Cus_test_data"
    start_time = time.time()
    nonce, hash_val = cus_proof_of_work_1(data, difficulty)
    elapsed = time.time() - start_time

    # 验证哈希确实以要求数量的 '0' 开头
    assert hash_val.startswith("0" * difficulty)

    # 打印观察结果
    print(f"\n[难度 {difficulty}] Nonce = {nonce}")
    print(f"哈希值: {hash_val}")
    print(f"耗时: {elapsed:.4f} 秒")

