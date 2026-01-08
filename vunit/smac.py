################################################################

# Author    : Ahmet MALAL
# Date      : 09.01.2026
# Project   : Python Implementation of SMAC Algorithm
# File      : smac.py

################################################################

DEBUG_LOG_LEVEL = 2 # Set debug log level (0: no logs, higher values for more verbosity)
smac_type_options = ['SMAC-1', 'SMAC-1/2', 'SMAC-3/4']  

class smac:
    def __init__(self, key, iv, type = 'SMAC-1',N = 1):
        self.Nb = 4 #don't change, for AES config
        self.Nk = 8 #don't change, for AES config
        self.sbox = self.generate_sbox() #S-box generation
        
        self.key = key
        self.iv = iv
        self.d = 9 #number of rounds for SMAC , Fixed to 9
        self.N = N # Number of parallel instances

        if type not in ['SMAC-1', 'SMAC-1/2', 'SMAC-3/4']:
            raise ValueError("Invalid SMAC type. Choose from 'SMAC-1', 'SMAC-1/2', 'SMAC-3/4'.")    
        else:
            self.type = type

        #second part of the key is assigned to x1, first part to x2, iv to x3
        self.a1,self.a2,self.a3 = key[16:32],key[0:16],iv 
        x1,x2,x3 = self.a1,self.a2,self.a3 

        self.one_star = [0x1]+[0x0]*15
        for i in range(0,self.d):
            x1,x2,x3 = self.smac_pi(x1,x2,x3,self.one_star)
        for i in range(0,16):
            self.a1[i] = self.a1[i] ^ x1[i]
            self.a2[i] = self.a2[i] ^ x2[i]
            self.a3[i] = self.a3[i] ^ x3[i]
        
        if DEBUG_LOG_LEVEL > 1:
            print("After Initilization:")
            print("A1:", ' '.join(hex(x) for x in self.a1))  
            print("A2:", ' '.join(hex(x) for x in self.a2))  
            print("A3:", ' '.join(hex(x) for x in self.a3))  

    def generate_sbox(self):
        C_SBOX = [
            0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
            0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
            0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
            0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
            0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
            0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
            0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
            0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
            0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
            0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
            0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
            0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
            0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
            0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
            0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
            0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16]
        return C_SBOX
    
    def add_round_key(self, state, round_key):
        res = [0]*(self.Nb*4)
        if DEBUG_LOG_LEVEL > 3:
            print("add_round_key_in         :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
            print("add_round_key_ round_key :",end=' ')
            for i in range(0,len(state)):
                print(hex(round_key[i]),end=' ')
            print()
        
        for i in range(0,len(state)):
            res[i] = state[i] ^ round_key[i]

        if DEBUG_LOG_LEVEL > 3:
            print("add_round_key_out        :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()
        return res

    def sub_bytes(self, state):
        if DEBUG_LOG_LEVEL > 3: 
            print("sub_bytes in             :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
        res = [0]*(self.Nb*4)
        for i in range(0,len(state)):
            res[i] = self.sbox[state[i]]
        if DEBUG_LOG_LEVEL > 3: 
            print("sub_bytes out            :",end=' ')
            for i in range(0,len(state)):
                print(hex(res[i]),end=' ')
            print()
        return res

    def rot_left(self,row,rot):
        res = [0]*len(row)
        for i in range(0,len(row)):
            res[i] = row[(i+rot)%len(row)]
        return res

    def shift_rows(self, state):

        if DEBUG_LOG_LEVEL > 3:
            print("sr_in                    :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
    
        res = [0]*self.Nb*4

        row0 = [0]*self.Nb
        row1 = [0]*self.Nb
        row2 = [0]*self.Nb
        row3 = [0]*self.Nb

        for i in range(0,self.Nb):
            row0[i] = state[4*i+0]
            row1[i] = state[4*i+1]
            row2[i] = state[4*i+2]
            row3[i] = state[4*i+3]

        if self.Nb == 4 or self.Nb == 5 or self.Nb == 6:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,2)
            row3 = self.rot_left(row3,3)    
        elif self.Nb == 7:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,2)
            row3 = self.rot_left(row3,4)  
        elif self.Nb == 8:
            row0 = self.rot_left(row0,0)
            row1 = self.rot_left(row1,1)
            row2 = self.rot_left(row2,3)
            row3 = self.rot_left(row3,4)  
        else: 
            raise ValueError("Invalid Nb")

        for i in range(0,self.Nb):
            res[4*i+0] = row0[i]
            res[4*i+1] = row1[i]
            res[4*i+2] = row2[i]
            res[4*i+3] = row3[i]

        if DEBUG_LOG_LEVEL > 3:
            print("sr_out                   :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()
    

        return res

    def mix_columns(self, state):
        # MixColumns transformation
        
        if DEBUG_LOG_LEVEL > 3:
            print("mix_in                   :",end=' ')
            for i in range(0,len(state)):
                print(hex(state[i]),end=' ')
            print()
        res = [0]*self.Nb*4

        for i in range(0,self.Nb):
            res[4*i+0] = self.mulby2(state[4*i+0])  ^ self.mulby3(state[4*i+1]) ^ state[4*i+2]              ^ state[4*i+3]
            res[4*i+1] = state[4*i+0]               ^ self.mulby2(state[4*i+1]) ^ self.mulby3(state[4*i+2]) ^ state[4*i+3]
            res[4*i+2] = state[4*i+0]               ^ state[4*i+1]              ^ self.mulby2(state[4*i+2]) ^ self.mulby3(state[4*i+3])
            res[4*i+3] = self.mulby3(state[4*i+0])  ^ state[4*i+1]              ^ state[4*i+2]              ^ self.mulby2(state[4*i+3]) 
        
        if DEBUG_LOG_LEVEL > 3:
            print("mix_out                  :",end=' ')
            for i in range(0,len(res)):
                print(hex(res[i]),end=' ')
            print()

        return res

    def mulby2(self, byte):
        # Multiply byte by 2 in GF(2^8)
        return ((byte << 1) ^ (0x1b if (byte & 0x80) else 0)) & 0xff
    
    def mulby3(self, byte):
        # Multiply byte by 2 in GF(2^8)
        return byte ^ self.mulby2(byte)

    def aes_round(self, state, round_key):
        state = self.sub_bytes(state)
        state = self.shift_rows(state)
        state = self.mix_columns(state)
        state = self.add_round_key(state, round_key)
        return state
    
    def smac_perm(self, state):

        #σ1 = {0,7,14,11,4,13,10,1,8,15,6,3,12,5,2,9} for SMAC-1
        #σ42 = {7,14,15,10,12,13,3,0,4,6,1,5,8,11,2,9} for SMAC-3/4
        #σ61 = {0,11,7,14,6,4,1,x15,9,3,8,5,13,2,10,12} for SMAC-1/2
        res = [0]*len(state)
        for i in range(0,len(state)):
            if self.type == 'SMAC-1':
                perm_index = [0,7,14,11,4,13,10,1,8,15,6,3,12,5,2,9]
            elif self.type == 'SMAC-3/4':
                perm_index = [7,14,15,10,12,13,3,0,4,6,1,5,8,11,2,9]
            elif self.type == 'SMAC-1/2':
                perm_index = [0,11,7,14,6,4,1,15,9,3,8,5,13,2,10,12]
            else:
                raise ValueError("Invalid SMAC type")
            res[i] = state[perm_index[i]]   

        return res
      
    def smac_pi(self,a1,a2,a3,m):
        # SMAC Pi function (Permutation)
        perm_in = [0]*len(a1)
        for i in range(0,len(perm_in)):
            perm_in[i] = a2[i] ^ a3[i] ^ m[i]
        r1 = self.smac_perm(perm_in)
        r2 = self.aes_round(a1,m)
        r3 = self.aes_round(a2,m)

        return r1,r2,r3
    
    def pad_to_block_size(self, data, block_size=16):
        """Pad data with zeroes to align to block_size"""
        remainder = len(data) % block_size
        if remainder != 0:
            padding_length = block_size - remainder
            data = data + [0x00] * padding_length
        return data
    
    def smac_compression(self,aad,cipher):
        len_a = 8*len(aad) #convert to bits
        len_c = 8*len(cipher) #convert ito bits
        # Convert len_a to bytes in 64-bit little-endian format
        len_a_bytes = len_a.to_bytes(8, byteorder='little')
        len_c_bytes = len_c.to_bytes(8, byteorder='little')

        len_a_bytes = list(len_a_bytes)
        len_c_bytes = list(len_c_bytes) 

        aad = self.pad_to_block_size(aad,16)
        cipher = self.pad_to_block_size(cipher,16)
        message_block = aad + cipher + len_a_bytes + len_c_bytes

        if DEBUG_LOG_LEVEL > 2:
            print("AAD Length (bytes):", len_a)
            print("Cipher Length (bytes):", len_c) 
            print("aad:", ' '.join(hex(x) for x in aad))
            
            print("len_a_bytes (bytes):", ' '.join(hex(x) for x in len_a_bytes))
            print("len_c_bytes (bytes):", ' '.join(hex(x) for x in len_c_bytes))
            print("AAD (bytes):", ' '.join(hex(x) for x in aad))

            print("Message Block Length (bytes):", len(message_block))
            print("Message Block (bytes):", ' '.join(hex(x) for x in message_block))

        num_blocks = len(message_block)//16

        for i in range(0,num_blocks):
            block = message_block[i*16:(i+1)*16]
            self.a1,self.a2,self.a3 = self.smac_pi(self.a1,self.a2,self.a3,block)

        if DEBUG_LOG_LEVEL > 1:
            print("After Compression:")
            print("A1:", ' '.join(hex(x) for x in self.a1))  
            print("A2:", ' '.join(hex(x) for x in self.a2))  
            print("A3:", ' '.join(hex(x) for x in self.a3))  
    
    def smac_finalize(self):
        x1,x2,x3 = self.a1,self.a2,self.a3
        for i in range(0,self.d):
            x1,x2,x3 = self.smac_pi(x1,x2,x3,self.one_star)
        for i in range(0,16):
            self.a1[i] = self.a1[i] ^ x1[i]
            self.a2[i] = self.a2[i] ^ x2[i]
            self.a3[i] = self.a3[i] ^ x3[i]
        
        if DEBUG_LOG_LEVEL > 1:
            print("After Finalization:")
            print("A1:", ' '.join(hex(x) for x in self.a1))  
            print("A2:", ' '.join(hex(x) for x in self.a2))  
            print("A3:", ' '.join(hex(x) for x in self.a3))  
        tag = self.a2
        return tag

################################################################


print("SMAC module begin...")

state   = [0,2,4,6]*16
rnd_key = [5]*16

key = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
       0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
       0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,
       0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f]


iv  = [0xff,0xfe,0xfd,0xfc,0xfb,0xfa,0xf9,0xf8,
       0xf7,0xf6,0xf5,0xf4,0xf3,0xf2,0xf1,0xf0]

aad = [0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
       0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,
       0x11,0x12,0x13]

cipher = [0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,
          0x1c,0x1d,0x1e,0x1f,0x20]

c = smac(key=key, iv=iv, type='SMAC-1')

c.smac_compression(cipher=cipher, aad=aad)
tag = c.smac_finalize()
print("Tag: ", end='')
for i in range(0,len(tag)):
    print(hex(tag[i]), end=' ')


print("\nSMAC module end...")

 


