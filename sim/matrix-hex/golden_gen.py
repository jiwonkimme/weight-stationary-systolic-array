import numpy as np
import os

def main():
    """
    Generates all 8 golden vector files required by the Verilog testbench.
    """
    
    # 1. 테스트벤치(TB_MAC_TOP.v)와 동일한 MNT 벡터
    #    (M, N, T) = (mnt[11:8], mnt[7:4], mnt[3:0])
    mnt_vectors = [
        0x444,  # Case 0
        0x337,  # Case 1
        0x374,  # Case 2
        0x376,  # Case 3
        0x634,  # Case 4
        0x738,  # Case 5
        0x583,  # Case 6
        0x656   # Case 7
    ]

    # 2. 고정된 8x8 입력 행렬 (input.hex의 내용과 일치)
    input_matrix = np.array([
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x01],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x01],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x01],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x01]
    ], dtype=np.uint64) # 정수 오버플로우 방지를 위해 64비트로 계산

    # 3. 고정된 8x8 전치된 가중치 행렬 (weight_transpose.hex의 내용과 일치)
    transposed_weight_matrix = np.array([
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08],
        [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
    ], dtype=np.uint64)

    print("Generating 8 Golden Vector Files...")

    # 4. 8개 케이스를 순회하며 파일 생성
    for i in range(8):
        mnt = mnt_vectors[i]
        
        # MNT 값 파싱 (1~8 범위)
        M = (mnt >> 8) & 0xF
        N = (mnt >> 4) & 0xF
        T = mnt & 0xF
        
        # Numpy 계산 (기존 코드와 동일)
        i_matrix = input_matrix[:T, :N]
        w_matrix = transposed_weight_matrix[:M, :N]
        transposed_w_matrix = w_matrix.T
        
        # (T x N) * (N x M) = (T x M) 결과 행렬
        result_matrix = np.dot(i_matrix, transposed_w_matrix)

        # 5. [핵심] (T x M) 행렬을 (16 x 1) 64-bit 메모리로 매핑
        # TB 주석 기반:
        # addr0: (1,1)...(1,4) -> 16bit * 4 = 64bit
        # addr1: (1,5)...(1,8) -> 16bit * 4 = 64bit
        # addr2: (2,1)...(2,4) -> 16bit * 4 = 64bit
        
        golden_mem = np.full(16, np.nan, dtype=object) # 16-entry 64-bit memory

        for t_idx in range(T):
            for m_idx in range(M):
                # (t_idx, m_idx) 결과를 16비트 값으로 가져옴
                val = int(result_matrix[t_idx, m_idx]) & 0xFFFF
                
                # 올바른 주소와 시프트 위치 계산
                addr  = t_idx * 2 + (m_idx // 4)
                # MSB 우선 Shift 계산
                shift = (3 - (m_idx % 4)) * 16

                if np.isnan(golden_mem[addr]):
                    golden_mem[addr] = np.uint64(0)
                
                # 64비트 워드에 16비트 결과값 패킹
                golden_mem[addr] |= np.uint64(val << shift)

        # 6. .hex 파일로 저장
        filename = f"golden_case_{i}.hex"

        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_path = os.path.join(script_dir, filename)
        
        with open(output_path, 'w') as f:
            for j in range(16):
                if np.isnan(golden_mem[j]):
                    hex_val = "x" * 16 # 64비트 'x'
                else:
                    # 64비트 정수를 16자리 16진수 문자열로 포맷
                    val_int = np.uint64(golden_mem[j])
                    hex_val = f"{val_int:016x}"
                f.write(hex_val + "\n")
        
        print(f"[SUCCESS] Generated {output_path} (MNT={mnt:x})")

if __name__ == "__main__":
    main()