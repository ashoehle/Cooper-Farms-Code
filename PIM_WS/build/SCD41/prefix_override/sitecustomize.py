import sys
if sys.prefix == '/usr':
    sys.real_prefix = sys.prefix
    sys.prefix = sys.exec_prefix = '/home/cooperfarms/POULTRY_IN_MOTION/PIM_WS/install/SCD41'
