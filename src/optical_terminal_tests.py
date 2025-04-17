import numpy as np
import matplotlib.pyplot as plt

# Optical terminal characteristics
buffer_capacity = 64 * 10**9 # 64 Gb
transmission_rate = 10**9 # 1 Gbps
#interface_speed = 10 * 10**6 # 10 Mbps
interface_speed = 900 * 10**6 #

# Test characteristics
data_to_downlink = 1100 * 10**9 # 1100 Gb
pass_time = 8 * 60 # 8 minutes

# Run test
time_range = np.arange(0, pass_time, 1)
buffer = np.zeros(len(time_range))
buffer[0] = buffer_capacity
for i in range(1, len(time_range)):
    buffer[i] = buffer[i-1] - transmission_rate + interface_speed
    if buffer[i] > buffer_capacity:
        buffer[i] = buffer_capacity
    if buffer[i] < 0:
        buffer[i] = 0

# Plot results
plt.plot([0, pass_time/60], [0, 0], 'r--')
plt.plot([0, pass_time/60], [buffer_capacity/10**9, buffer_capacity/10**9], 'r--')
plt.plot(time_range/60, buffer/10**9)
plt.title('Buffer status (during downlink)')
plt.xlabel('Time (mins)')
plt.ylabel('Buffer status (Gb)')
plt.show()

# Test refill time
refill_time = buffer_capacity / interface_speed
print('Refill time:', refill_time/60, 'mins')


