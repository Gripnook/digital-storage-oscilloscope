-- -------------------------------------------------------------
--
-- Module: Hlp2
-- Generated by MATLAB(R) 9.2 and the Filter Design HDL Coder 3.1.1.
-- Generated on: 2017-03-24 11:20:29
-- -------------------------------------------------------------

-- -------------------------------------------------------------
-- HDL Code Generation Options:
--
-- TargetLanguage: VHDL
-- FIRAdderStyle: tree
-- OptimizeForHDL: on
-- ClockEnableInputPort: enable
-- ClockInputPort: clock
-- AddPipelineRegisters: on
-- Name: Hlp2
-- TestBenchName: Hlp2_tb
-- TestBenchStimulus: impulse step ramp chirp noise 

-- Filter Specifications:
--
-- Sample Rate     : 500 kHz
-- Response        : Lowpass
-- Specification   : Fp,Fst,Ap,Ast
-- Passband Edge   : 100 kHz
-- Stopband Atten. : 80 dB
-- Passband Ripple : 0.01 dB
-- Stopband Edge   : 150 kHz
-- -------------------------------------------------------------

-- -------------------------------------------------------------
-- HDL Implementation    : Fully parallel
-- Folding Factor        : 1
-- -------------------------------------------------------------
-- Filter Settings:
--
-- Discrete-Time FIR Filter (real)
-- -------------------------------
-- Filter Structure  : Direct-Form FIR
-- Filter Length     : 43
-- Stable            : Yes
-- Linear Phase      : Yes (Type 1)
-- Arithmetic        : fixed
-- Numerator         : s16,16 -> [-5.000000e-01 5.000000e-01)
-- Input             : s13,0 -> [-4096 4096)
-- Filter Internals  : Full Precision
--   Output          : s30,16 -> [-8192 8192)  (auto determined)
--   Product         : s28,16 -> [-2048 2048)  (auto determined)
--   Accumulator     : s30,16 -> [-8192 8192)  (auto determined)
--   Round Mode      : No rounding
--   Overflow Mode   : No overflow
-- -------------------------------------------------------------



LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.ALL;

ENTITY Hlp2 IS
   PORT( clock                           :   IN    std_logic; 
         enable                          :   IN    std_logic; 
         reset                           :   IN    std_logic; 
         filter_in                       :   IN    std_logic_vector(12 DOWNTO 0); -- sfix13
         filter_out                      :   OUT   std_logic_vector(29 DOWNTO 0)  -- sfix30_En16
         );

END Hlp2;


----------------------------------------------------------------
--Module Architecture: Hlp2
----------------------------------------------------------------
ARCHITECTURE rtl OF Hlp2 IS
  -- Local Functions
  -- Type Definitions
  TYPE delay_pipeline_type IS ARRAY (NATURAL range <>) OF signed(12 DOWNTO 0); -- sfix13
  -- Constants
  CONSTANT coeff1                         : signed(15 DOWNTO 0) := to_signed(4, 16); -- sfix16_En16
  CONSTANT coeff2                         : signed(15 DOWNTO 0) := to_signed(-26, 16); -- sfix16_En16
  CONSTANT coeff3                         : signed(15 DOWNTO 0) := to_signed(-44, 16); -- sfix16_En16
  CONSTANT coeff4                         : signed(15 DOWNTO 0) := to_signed(46, 16); -- sfix16_En16
  CONSTANT coeff5                         : signed(15 DOWNTO 0) := to_signed(111, 16); -- sfix16_En16
  CONSTANT coeff6                         : signed(15 DOWNTO 0) := to_signed(-83, 16); -- sfix16_En16
  CONSTANT coeff7                         : signed(15 DOWNTO 0) := to_signed(-238, 16); -- sfix16_En16
  CONSTANT coeff8                         : signed(15 DOWNTO 0) := to_signed(131, 16); -- sfix16_En16
  CONSTANT coeff9                         : signed(15 DOWNTO 0) := to_signed(450, 16); -- sfix16_En16
  CONSTANT coeff10                        : signed(15 DOWNTO 0) := to_signed(-190, 16); -- sfix16_En16
  CONSTANT coeff11                        : signed(15 DOWNTO 0) := to_signed(-786, 16); -- sfix16_En16
  CONSTANT coeff12                        : signed(15 DOWNTO 0) := to_signed(255, 16); -- sfix16_En16
  CONSTANT coeff13                        : signed(15 DOWNTO 0) := to_signed(1304, 16); -- sfix16_En16
  CONSTANT coeff14                        : signed(15 DOWNTO 0) := to_signed(-321, 16); -- sfix16_En16
  CONSTANT coeff15                        : signed(15 DOWNTO 0) := to_signed(-2117, 16); -- sfix16_En16
  CONSTANT coeff16                        : signed(15 DOWNTO 0) := to_signed(382, 16); -- sfix16_En16
  CONSTANT coeff17                        : signed(15 DOWNTO 0) := to_signed(3512, 16); -- sfix16_En16
  CONSTANT coeff18                        : signed(15 DOWNTO 0) := to_signed(-432, 16); -- sfix16_En16
  CONSTANT coeff19                        : signed(15 DOWNTO 0) := to_signed(-6539, 16); -- sfix16_En16
  CONSTANT coeff20                        : signed(15 DOWNTO 0) := to_signed(464, 16); -- sfix16_En16
  CONSTANT coeff21                        : signed(15 DOWNTO 0) := to_signed(20719, 16); -- sfix16_En16
  CONSTANT coeff22                        : signed(15 DOWNTO 0) := to_signed(32293, 16); -- sfix16_En16
  CONSTANT coeff23                        : signed(15 DOWNTO 0) := to_signed(20719, 16); -- sfix16_En16
  CONSTANT coeff24                        : signed(15 DOWNTO 0) := to_signed(464, 16); -- sfix16_En16
  CONSTANT coeff25                        : signed(15 DOWNTO 0) := to_signed(-6539, 16); -- sfix16_En16
  CONSTANT coeff26                        : signed(15 DOWNTO 0) := to_signed(-432, 16); -- sfix16_En16
  CONSTANT coeff27                        : signed(15 DOWNTO 0) := to_signed(3512, 16); -- sfix16_En16
  CONSTANT coeff28                        : signed(15 DOWNTO 0) := to_signed(382, 16); -- sfix16_En16
  CONSTANT coeff29                        : signed(15 DOWNTO 0) := to_signed(-2117, 16); -- sfix16_En16
  CONSTANT coeff30                        : signed(15 DOWNTO 0) := to_signed(-321, 16); -- sfix16_En16
  CONSTANT coeff31                        : signed(15 DOWNTO 0) := to_signed(1304, 16); -- sfix16_En16
  CONSTANT coeff32                        : signed(15 DOWNTO 0) := to_signed(255, 16); -- sfix16_En16
  CONSTANT coeff33                        : signed(15 DOWNTO 0) := to_signed(-786, 16); -- sfix16_En16
  CONSTANT coeff34                        : signed(15 DOWNTO 0) := to_signed(-190, 16); -- sfix16_En16
  CONSTANT coeff35                        : signed(15 DOWNTO 0) := to_signed(450, 16); -- sfix16_En16
  CONSTANT coeff36                        : signed(15 DOWNTO 0) := to_signed(131, 16); -- sfix16_En16
  CONSTANT coeff37                        : signed(15 DOWNTO 0) := to_signed(-238, 16); -- sfix16_En16
  CONSTANT coeff38                        : signed(15 DOWNTO 0) := to_signed(-83, 16); -- sfix16_En16
  CONSTANT coeff39                        : signed(15 DOWNTO 0) := to_signed(111, 16); -- sfix16_En16
  CONSTANT coeff40                        : signed(15 DOWNTO 0) := to_signed(46, 16); -- sfix16_En16
  CONSTANT coeff41                        : signed(15 DOWNTO 0) := to_signed(-44, 16); -- sfix16_En16
  CONSTANT coeff42                        : signed(15 DOWNTO 0) := to_signed(-26, 16); -- sfix16_En16
  CONSTANT coeff43                        : signed(15 DOWNTO 0) := to_signed(4, 16); -- sfix16_En16

  -- Signals
  SIGNAL delay_pipeline                   : delay_pipeline_type(0 TO 42); -- sfix13
  SIGNAL product43                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL product42                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp                         : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product41                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_1                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product40                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_2                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product39                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_3                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product38                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_4                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product37                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_5                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product36                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_6                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product35                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_7                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product34                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_8                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product33                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_9                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product32                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_10                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product31                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_11                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product30                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_12                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product29                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_13                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product28                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_14                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product27                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_15                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product26                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_16                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product25                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_17                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product24                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_18                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product23                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_19                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product22                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_20                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product21                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_21                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product20                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_22                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product19                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_23                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product18                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_24                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product17                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_25                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product16                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_26                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product15                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_27                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product14                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_28                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product13                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_29                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product12                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_30                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product11                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_31                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product10                        : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_32                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product9                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_33                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product8                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_34                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product7                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_35                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product6                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_36                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product5                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_37                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product4                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_38                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product3                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_39                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product2                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL mul_temp_40                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL product1                         : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL sum_final                        : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp                         : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_2                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_1                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_2                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_3                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_2                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_3                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_4                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_3                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_4                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_5                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_4                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_5                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_6                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_5                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_6                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_7                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_6                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_7                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_8                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_7                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_8                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_9                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_8                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_9                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_10                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_9                       : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_10                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_11                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_10                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_11                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_12                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_11                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_12                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_13                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_12                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_13                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_14                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_13                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_14                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_15                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_14                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_15                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_16                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_15                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_16                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_17                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_16                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_17                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_18                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_17                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_18                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_19                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_18                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_19                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_20                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_19                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_20                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum1_21                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_20                      : signed(28 DOWNTO 0); -- sfix29_En16
  SIGNAL sumpipe1_21                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sumpipe1_22                      : signed(27 DOWNTO 0); -- sfix28_En16
  SIGNAL sum2_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_21                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_2                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_22                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_2                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_3                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_23                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_3                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_4                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_24                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_4                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_5                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_25                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_5                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_6                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_26                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_6                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_7                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_27                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_7                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_8                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_28                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_8                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_9                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_29                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_9                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_10                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_30                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_10                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum2_11                          : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_31                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe2_11                      : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum3_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_32                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe3_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum3_2                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_33                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe3_2                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum3_3                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_34                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe3_3                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum3_4                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_35                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe3_4                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum3_5                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_36                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe3_5                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sumpipe3_6                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum4_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_37                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe4_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum4_2                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_38                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe4_2                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum4_3                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_39                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe4_3                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum5_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_40                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe5_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sumpipe5_2                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL sum6_1                           : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL add_temp_41                      : signed(30 DOWNTO 0); -- sfix31_En16
  SIGNAL sumpipe6_1                       : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL output_typeconvert               : signed(29 DOWNTO 0); -- sfix30_En16
  SIGNAL output_register                  : signed(29 DOWNTO 0); -- sfix30_En16


BEGIN

  -- Block Statements
  Delay_Pipeline_process : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      delay_pipeline(0 TO 42) <= (OTHERS => (OTHERS => '0'));
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        delay_pipeline(0) <= signed(filter_in);
        delay_pipeline(1 TO 42) <= delay_pipeline(0 TO 41);
      END IF;
    END IF; 
  END PROCESS Delay_Pipeline_process;

  product43 <= resize(delay_pipeline(42)(12 DOWNTO 0) & '0' & '0', 28);

  mul_temp <= delay_pipeline(41) * coeff42;
  product42 <= mul_temp(27 DOWNTO 0);

  mul_temp_1 <= delay_pipeline(40) * coeff41;
  product41 <= mul_temp_1(27 DOWNTO 0);

  mul_temp_2 <= delay_pipeline(39) * coeff40;
  product40 <= mul_temp_2(27 DOWNTO 0);

  mul_temp_3 <= delay_pipeline(38) * coeff39;
  product39 <= mul_temp_3(27 DOWNTO 0);

  mul_temp_4 <= delay_pipeline(37) * coeff38;
  product38 <= mul_temp_4(27 DOWNTO 0);

  mul_temp_5 <= delay_pipeline(36) * coeff37;
  product37 <= mul_temp_5(27 DOWNTO 0);

  mul_temp_6 <= delay_pipeline(35) * coeff36;
  product36 <= mul_temp_6(27 DOWNTO 0);

  mul_temp_7 <= delay_pipeline(34) * coeff35;
  product35 <= mul_temp_7(27 DOWNTO 0);

  mul_temp_8 <= delay_pipeline(33) * coeff34;
  product34 <= mul_temp_8(27 DOWNTO 0);

  mul_temp_9 <= delay_pipeline(32) * coeff33;
  product33 <= mul_temp_9(27 DOWNTO 0);

  mul_temp_10 <= delay_pipeline(31) * coeff32;
  product32 <= mul_temp_10(27 DOWNTO 0);

  mul_temp_11 <= delay_pipeline(30) * coeff31;
  product31 <= mul_temp_11(27 DOWNTO 0);

  mul_temp_12 <= delay_pipeline(29) * coeff30;
  product30 <= mul_temp_12(27 DOWNTO 0);

  mul_temp_13 <= delay_pipeline(28) * coeff29;
  product29 <= mul_temp_13(27 DOWNTO 0);

  mul_temp_14 <= delay_pipeline(27) * coeff28;
  product28 <= mul_temp_14(27 DOWNTO 0);

  mul_temp_15 <= delay_pipeline(26) * coeff27;
  product27 <= mul_temp_15(27 DOWNTO 0);

  mul_temp_16 <= delay_pipeline(25) * coeff26;
  product26 <= mul_temp_16(27 DOWNTO 0);

  mul_temp_17 <= delay_pipeline(24) * coeff25;
  product25 <= mul_temp_17(27 DOWNTO 0);

  mul_temp_18 <= delay_pipeline(23) * coeff24;
  product24 <= mul_temp_18(27 DOWNTO 0);

  mul_temp_19 <= delay_pipeline(22) * coeff23;
  product23 <= mul_temp_19(27 DOWNTO 0);

  mul_temp_20 <= delay_pipeline(21) * coeff22;
  product22 <= mul_temp_20(27 DOWNTO 0);

  mul_temp_21 <= delay_pipeline(20) * coeff21;
  product21 <= mul_temp_21(27 DOWNTO 0);

  mul_temp_22 <= delay_pipeline(19) * coeff20;
  product20 <= mul_temp_22(27 DOWNTO 0);

  mul_temp_23 <= delay_pipeline(18) * coeff19;
  product19 <= mul_temp_23(27 DOWNTO 0);

  mul_temp_24 <= delay_pipeline(17) * coeff18;
  product18 <= mul_temp_24(27 DOWNTO 0);

  mul_temp_25 <= delay_pipeline(16) * coeff17;
  product17 <= mul_temp_25(27 DOWNTO 0);

  mul_temp_26 <= delay_pipeline(15) * coeff16;
  product16 <= mul_temp_26(27 DOWNTO 0);

  mul_temp_27 <= delay_pipeline(14) * coeff15;
  product15 <= mul_temp_27(27 DOWNTO 0);

  mul_temp_28 <= delay_pipeline(13) * coeff14;
  product14 <= mul_temp_28(27 DOWNTO 0);

  mul_temp_29 <= delay_pipeline(12) * coeff13;
  product13 <= mul_temp_29(27 DOWNTO 0);

  mul_temp_30 <= delay_pipeline(11) * coeff12;
  product12 <= mul_temp_30(27 DOWNTO 0);

  mul_temp_31 <= delay_pipeline(10) * coeff11;
  product11 <= mul_temp_31(27 DOWNTO 0);

  mul_temp_32 <= delay_pipeline(9) * coeff10;
  product10 <= mul_temp_32(27 DOWNTO 0);

  mul_temp_33 <= delay_pipeline(8) * coeff9;
  product9 <= mul_temp_33(27 DOWNTO 0);

  mul_temp_34 <= delay_pipeline(7) * coeff8;
  product8 <= mul_temp_34(27 DOWNTO 0);

  mul_temp_35 <= delay_pipeline(6) * coeff7;
  product7 <= mul_temp_35(27 DOWNTO 0);

  mul_temp_36 <= delay_pipeline(5) * coeff6;
  product6 <= mul_temp_36(27 DOWNTO 0);

  mul_temp_37 <= delay_pipeline(4) * coeff5;
  product5 <= mul_temp_37(27 DOWNTO 0);

  mul_temp_38 <= delay_pipeline(3) * coeff4;
  product4 <= mul_temp_38(27 DOWNTO 0);

  mul_temp_39 <= delay_pipeline(2) * coeff3;
  product3 <= mul_temp_39(27 DOWNTO 0);

  mul_temp_40 <= delay_pipeline(1) * coeff2;
  product2 <= mul_temp_40(27 DOWNTO 0);

  product1 <= resize(delay_pipeline(0)(12 DOWNTO 0) & '0' & '0', 28);

  add_temp <= resize(product43, 29) + resize(product42, 29);
  sum1_1 <= resize(add_temp, 30);

  add_temp_1 <= resize(product41, 29) + resize(product40, 29);
  sum1_2 <= resize(add_temp_1, 30);

  add_temp_2 <= resize(product39, 29) + resize(product38, 29);
  sum1_3 <= resize(add_temp_2, 30);

  add_temp_3 <= resize(product37, 29) + resize(product36, 29);
  sum1_4 <= resize(add_temp_3, 30);

  add_temp_4 <= resize(product35, 29) + resize(product34, 29);
  sum1_5 <= resize(add_temp_4, 30);

  add_temp_5 <= resize(product33, 29) + resize(product32, 29);
  sum1_6 <= resize(add_temp_5, 30);

  add_temp_6 <= resize(product31, 29) + resize(product30, 29);
  sum1_7 <= resize(add_temp_6, 30);

  add_temp_7 <= resize(product29, 29) + resize(product28, 29);
  sum1_8 <= resize(add_temp_7, 30);

  add_temp_8 <= resize(product27, 29) + resize(product26, 29);
  sum1_9 <= resize(add_temp_8, 30);

  add_temp_9 <= resize(product25, 29) + resize(product24, 29);
  sum1_10 <= resize(add_temp_9, 30);

  add_temp_10 <= resize(product23, 29) + resize(product22, 29);
  sum1_11 <= resize(add_temp_10, 30);

  add_temp_11 <= resize(product21, 29) + resize(product20, 29);
  sum1_12 <= resize(add_temp_11, 30);

  add_temp_12 <= resize(product19, 29) + resize(product18, 29);
  sum1_13 <= resize(add_temp_12, 30);

  add_temp_13 <= resize(product17, 29) + resize(product16, 29);
  sum1_14 <= resize(add_temp_13, 30);

  add_temp_14 <= resize(product15, 29) + resize(product14, 29);
  sum1_15 <= resize(add_temp_14, 30);

  add_temp_15 <= resize(product13, 29) + resize(product12, 29);
  sum1_16 <= resize(add_temp_15, 30);

  add_temp_16 <= resize(product11, 29) + resize(product10, 29);
  sum1_17 <= resize(add_temp_16, 30);

  add_temp_17 <= resize(product9, 29) + resize(product8, 29);
  sum1_18 <= resize(add_temp_17, 30);

  add_temp_18 <= resize(product7, 29) + resize(product6, 29);
  sum1_19 <= resize(add_temp_18, 30);

  add_temp_19 <= resize(product5, 29) + resize(product4, 29);
  sum1_20 <= resize(add_temp_19, 30);

  add_temp_20 <= resize(product3, 29) + resize(product2, 29);
  sum1_21 <= resize(add_temp_20, 30);

  temp_process1 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe1_1 <= (OTHERS => '0');
      sumpipe1_2 <= (OTHERS => '0');
      sumpipe1_3 <= (OTHERS => '0');
      sumpipe1_4 <= (OTHERS => '0');
      sumpipe1_5 <= (OTHERS => '0');
      sumpipe1_6 <= (OTHERS => '0');
      sumpipe1_7 <= (OTHERS => '0');
      sumpipe1_8 <= (OTHERS => '0');
      sumpipe1_9 <= (OTHERS => '0');
      sumpipe1_10 <= (OTHERS => '0');
      sumpipe1_11 <= (OTHERS => '0');
      sumpipe1_12 <= (OTHERS => '0');
      sumpipe1_13 <= (OTHERS => '0');
      sumpipe1_14 <= (OTHERS => '0');
      sumpipe1_15 <= (OTHERS => '0');
      sumpipe1_16 <= (OTHERS => '0');
      sumpipe1_17 <= (OTHERS => '0');
      sumpipe1_18 <= (OTHERS => '0');
      sumpipe1_19 <= (OTHERS => '0');
      sumpipe1_20 <= (OTHERS => '0');
      sumpipe1_21 <= (OTHERS => '0');
      sumpipe1_22 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe1_1 <= sum1_1;
        sumpipe1_2 <= sum1_2;
        sumpipe1_3 <= sum1_3;
        sumpipe1_4 <= sum1_4;
        sumpipe1_5 <= sum1_5;
        sumpipe1_6 <= sum1_6;
        sumpipe1_7 <= sum1_7;
        sumpipe1_8 <= sum1_8;
        sumpipe1_9 <= sum1_9;
        sumpipe1_10 <= sum1_10;
        sumpipe1_11 <= sum1_11;
        sumpipe1_12 <= sum1_12;
        sumpipe1_13 <= sum1_13;
        sumpipe1_14 <= sum1_14;
        sumpipe1_15 <= sum1_15;
        sumpipe1_16 <= sum1_16;
        sumpipe1_17 <= sum1_17;
        sumpipe1_18 <= sum1_18;
        sumpipe1_19 <= sum1_19;
        sumpipe1_20 <= sum1_20;
        sumpipe1_21 <= sum1_21;
        sumpipe1_22 <= product1;
      END IF;
    END IF; 
  END PROCESS temp_process1;

  add_temp_21 <= resize(sumpipe1_1, 31) + resize(sumpipe1_2, 31);
  sum2_1 <= add_temp_21(29 DOWNTO 0);

  add_temp_22 <= resize(sumpipe1_3, 31) + resize(sumpipe1_4, 31);
  sum2_2 <= add_temp_22(29 DOWNTO 0);

  add_temp_23 <= resize(sumpipe1_5, 31) + resize(sumpipe1_6, 31);
  sum2_3 <= add_temp_23(29 DOWNTO 0);

  add_temp_24 <= resize(sumpipe1_7, 31) + resize(sumpipe1_8, 31);
  sum2_4 <= add_temp_24(29 DOWNTO 0);

  add_temp_25 <= resize(sumpipe1_9, 31) + resize(sumpipe1_10, 31);
  sum2_5 <= add_temp_25(29 DOWNTO 0);

  add_temp_26 <= resize(sumpipe1_11, 31) + resize(sumpipe1_12, 31);
  sum2_6 <= add_temp_26(29 DOWNTO 0);

  add_temp_27 <= resize(sumpipe1_13, 31) + resize(sumpipe1_14, 31);
  sum2_7 <= add_temp_27(29 DOWNTO 0);

  add_temp_28 <= resize(sumpipe1_15, 31) + resize(sumpipe1_16, 31);
  sum2_8 <= add_temp_28(29 DOWNTO 0);

  add_temp_29 <= resize(sumpipe1_17, 31) + resize(sumpipe1_18, 31);
  sum2_9 <= add_temp_29(29 DOWNTO 0);

  add_temp_30 <= resize(sumpipe1_19, 31) + resize(sumpipe1_20, 31);
  sum2_10 <= add_temp_30(29 DOWNTO 0);

  add_temp_31 <= resize(sumpipe1_21, 31) + resize(sumpipe1_22, 31);
  sum2_11 <= add_temp_31(29 DOWNTO 0);

  temp_process2 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe2_1 <= (OTHERS => '0');
      sumpipe2_2 <= (OTHERS => '0');
      sumpipe2_3 <= (OTHERS => '0');
      sumpipe2_4 <= (OTHERS => '0');
      sumpipe2_5 <= (OTHERS => '0');
      sumpipe2_6 <= (OTHERS => '0');
      sumpipe2_7 <= (OTHERS => '0');
      sumpipe2_8 <= (OTHERS => '0');
      sumpipe2_9 <= (OTHERS => '0');
      sumpipe2_10 <= (OTHERS => '0');
      sumpipe2_11 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe2_1 <= sum2_1;
        sumpipe2_2 <= sum2_2;
        sumpipe2_3 <= sum2_3;
        sumpipe2_4 <= sum2_4;
        sumpipe2_5 <= sum2_5;
        sumpipe2_6 <= sum2_6;
        sumpipe2_7 <= sum2_7;
        sumpipe2_8 <= sum2_8;
        sumpipe2_9 <= sum2_9;
        sumpipe2_10 <= sum2_10;
        sumpipe2_11 <= sum2_11;
      END IF;
    END IF; 
  END PROCESS temp_process2;

  add_temp_32 <= resize(sumpipe2_1, 31) + resize(sumpipe2_2, 31);
  sum3_1 <= add_temp_32(29 DOWNTO 0);

  add_temp_33 <= resize(sumpipe2_3, 31) + resize(sumpipe2_4, 31);
  sum3_2 <= add_temp_33(29 DOWNTO 0);

  add_temp_34 <= resize(sumpipe2_5, 31) + resize(sumpipe2_6, 31);
  sum3_3 <= add_temp_34(29 DOWNTO 0);

  add_temp_35 <= resize(sumpipe2_7, 31) + resize(sumpipe2_8, 31);
  sum3_4 <= add_temp_35(29 DOWNTO 0);

  add_temp_36 <= resize(sumpipe2_9, 31) + resize(sumpipe2_10, 31);
  sum3_5 <= add_temp_36(29 DOWNTO 0);

  temp_process3 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe3_1 <= (OTHERS => '0');
      sumpipe3_2 <= (OTHERS => '0');
      sumpipe3_3 <= (OTHERS => '0');
      sumpipe3_4 <= (OTHERS => '0');
      sumpipe3_5 <= (OTHERS => '0');
      sumpipe3_6 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe3_1 <= sum3_1;
        sumpipe3_2 <= sum3_2;
        sumpipe3_3 <= sum3_3;
        sumpipe3_4 <= sum3_4;
        sumpipe3_5 <= sum3_5;
        sumpipe3_6 <= sumpipe2_11;
      END IF;
    END IF; 
  END PROCESS temp_process3;

  add_temp_37 <= resize(sumpipe3_1, 31) + resize(sumpipe3_2, 31);
  sum4_1 <= add_temp_37(29 DOWNTO 0);

  add_temp_38 <= resize(sumpipe3_3, 31) + resize(sumpipe3_4, 31);
  sum4_2 <= add_temp_38(29 DOWNTO 0);

  add_temp_39 <= resize(sumpipe3_5, 31) + resize(sumpipe3_6, 31);
  sum4_3 <= add_temp_39(29 DOWNTO 0);

  temp_process4 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe4_1 <= (OTHERS => '0');
      sumpipe4_2 <= (OTHERS => '0');
      sumpipe4_3 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe4_1 <= sum4_1;
        sumpipe4_2 <= sum4_2;
        sumpipe4_3 <= sum4_3;
      END IF;
    END IF; 
  END PROCESS temp_process4;

  add_temp_40 <= resize(sumpipe4_1, 31) + resize(sumpipe4_2, 31);
  sum5_1 <= add_temp_40(29 DOWNTO 0);

  temp_process5 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe5_1 <= (OTHERS => '0');
      sumpipe5_2 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe5_1 <= sum5_1;
        sumpipe5_2 <= sumpipe4_3;
      END IF;
    END IF; 
  END PROCESS temp_process5;

  add_temp_41 <= resize(sumpipe5_1, 31) + resize(sumpipe5_2, 31);
  sum6_1 <= add_temp_41(29 DOWNTO 0);

  temp_process6 : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      sumpipe6_1 <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        sumpipe6_1 <= sum6_1;
      END IF;
    END IF; 
  END PROCESS temp_process6;

  sum_final <= sumpipe6_1;

  output_typeconvert <= sum_final;

  Output_Register_process : PROCESS (clock, reset)
  BEGIN
    IF reset = '1' THEN
      output_register <= (OTHERS => '0');
    ELSIF clock'event AND clock = '1' THEN
      IF enable = '1' THEN
        output_register <= output_typeconvert;
      END IF;
    END IF; 
  END PROCESS Output_Register_process;

  -- Assignment Statements
  filter_out <= std_logic_vector(output_register);
END rtl;
