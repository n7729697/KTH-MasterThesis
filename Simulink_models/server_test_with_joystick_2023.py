import pygame
import socket
import struct
from perpetualtimer import *
import adafruit_bno055 
import board
import qwiic
import RPi.GPIO as GPIO
import serial
import numpy as np
import socket,os
import time
import threading
import mmap

def ToFsetup(XSHUT_i,i2c_i):
    # ToF Setup
    ToF_i = i2c_i - 33
    GPIO.output(XSHUT_i, GPIO.HIGH)

    time.sleep(0.2)
    
    ToF[ToF_i] = qwiic.QwiicVL53L1X()
    ToF[ToF_i].sensor_init()
    if (ToF[ToF_i].sensor_init() == None):                  # Begin returns 0 on a good init
        print("ToF Sensor", ToF_i+1, "online!")
    time.sleep(0.2)
    ToF[ToF_i].set_i2c_address(i2c_i)
    time.sleep(0.2)
    ToF[ToF_i].start_ranging()
    time.sleep(0.2)
    
# ToF Setup
# ToF_12345=front,back,left,right,down
# XSHUT = [18, 20, 21, 16, 7]
XSHUT = [16, 18, 7, 20, 21]
i2c = [0x21, 0x22, 0x23, 0x24, 0x25]
ToF = [None for _ in range(5)]
GPIO.setmode(GPIO.BCM)

for i in range(5):
    GPIO.setup(XSHUT[i], GPIO.OUT)
    GPIO.output(XSHUT[i], GPIO.LOW)
    try:
        ToFsetup(XSHUT[i], i2c[i])
    except:
        print("ToF ", i, "not working!")
    
#IMU SETUP
i2c=board.I2C()
try:
    IMU = adafruit_bno055.BNO055_I2C(i2c=i2c)
    time.sleep(0.5)
    print('IMU online!')
except:
    for i in range(100):
        print('Error Initializing IMU! Keep trying... ',i+1,' times!')
        try:
            time.sleep(0.05)
            IMU = adafruit_bno055.BNO055_I2C(i2c=i2c)
            break
        except:
            1
        
    print('Initializing IMU failed! Try again later!')
    exit()
#IMU SETUP
    
#Serial Setup
# try:
#     ser = serial.Serial("/dev/ttyAMA0", 115200, timeout = 0.05)
#     ser.flushInput()
#     ser.flushOutput()
#     time.sleep(1)
#     print('Serial connected to STM32!')
# except:
#     print('Error Initializing serial connection!') 
#Serial Setup

#UDP Transmission

# HOST1 = Commands
# HOST2 = Feedback

#HOST1 = '192.168.1.33'  # Standard loopback interface address (localhost)
HOST1 = '0.0.0.0'
PORT1 = 50005

#HOST2 = '192.168.1.35'  # Standard loopback interface address (localhost)
HOST2 = '0.0.0.0'
PORT2 = 50006        # Port to listen on (non-privileged ports are > 1023)

sock1 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock2 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

sock1.bind((HOST1, PORT1))
#sock2.connect((HOST2, PORT2))

#sock1.settimeout(0.0)
#sock2.settimeout(0.0)
#UDP Tranmissions

# Initialize the joysticks.
try:
    pygame.init()
    pygame.joystick.init()
except:
    print('joysticks not connectted or error!')
    quit()
# Initialize the joysticks.

# data initial
motor_commands = bytearray([90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90])
relay_commands = bytearray([10, 10])
# transmission_array_STM32 = bytearray([83, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 10, 10, 0, 55, 69])
# FSR_temp = bytearray([65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66])
# data_from_Simulink = b'A'
data_to_Simulink = b'A'
countdown_flag = 0

with open( "./bin_file/Motor_Positions.bin", "rb+" ) as fd:
    fd.truncate(18)
    mm = mmap.mmap(fd.fileno(), 0)
    
with open('./bin_file/FSR_Values.bin', 'rb+') as file:
    FSR = bytearray([65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66])
    file.write(FSR)
    mm1 = mmap.mmap(file.fileno(), 0, access=mmap.ACCESS_READ)
    mm1.seek(0)
    binary_data = mm1.read()
    float_data_array = [None] * int(len(binary_data)/4)

def UDP_Transmit():

    global data_to_Simulink
    #FSRdata=FSR_temp[1:17]
    #intdata1 = struct.unpack("f", FSRdata[0:4])
    #print('UDP_Transmit')
    Read_Sensors_Compose_Data()
    try:
        #print('before read')
        #print('after read')
        '''distancex = np.mean(dis1)
        distancey = np.mean(dis2)
        distancez = np.mean(dis3)'''
#         print("data_to_Simulink",list(data_to_Simulink))
        #print(velocity1)
        sock2.sendto(data_to_Simulink, (HOST2, PORT2))
        #print(vel1)
#         print("Transmission to Simulink Successful")
    except:
        print("UDP Transmit to Simulink failed")
        exit()

def UDP_Recieve():

    global countdown_flag
    global motor_commands

    try:
        
        motor_commands = sock1.recv(1024)
#         print('Received motor_commands: ', list(motor_commands))
        if len(motor_commands) == 12:
            countdown_flag = 1
            #print("Recvd")
            #print(motor_commands.hex())

    except:
        print("UDP Receive from Simulink failed")
        

def Read_Sensors_Compose_Data():
    global data_to_Simulink
    
    #joystick Event Get
    try:
        pygame.event.get()
        joystick = pygame.joystick.Joystick(0)
        joystick.init()
    except:
        print('Joystick not working or connected!')
#     print('before Stm32')
#     Serial Write then Read
    try:
        Write_STM32()
    except:
        print('write to STM32 failed at Read_Sensors_Compose_Data!')
    
    
    distance_front = ToF[0].get_distance()
    time.sleep(0.001)
    distance_back = ToF[1].get_distance()
    time.sleep(0.001)
    distance_left = ToF[2].get_distance()
    time.sleep(0.001)
    distance_right = ToF[3].get_distance()
    time.sleep(0.001)
    distance_down = ToF[4].get_distance()
    time.sleep(0.001)
    
#     print(distance_front,distance_back,distance_left,distance_right,distance_down)

    distance_data = bytearray(struct.pack("f",distance_front)) + bytearray(struct.pack("f",distance_back)) + bytearray(struct.pack("f",distance_left)) + bytearray(struct.pack("f",distance_right)) + bytearray(struct.pack("f",distance_down))
    
#     distance3 = 500

#     print(distance3)

#     distance_sensors = bytearray(struct.pack("f", distance1)) +  bytearray(struct.pack("f", distance2)) + bytearray(struct.pack("f", distance3))

    quaternion = IMU.quaternion
#     print(IMU.acceleration,IMU.calibration_status)
#     print(quaternion)

    IMU_Readings = bytearray(struct.pack("f", quaternion[0]))\
                   + bytearray(struct.pack("f", quaternion[1]))\
                   + bytearray(struct.pack("f", quaternion[2]))\
                   + bytearray(struct.pack("f", quaternion[3]))
    
    euler = quaternion_to_euler_angle_vectorized1(quaternion[0], quaternion[1], quaternion[2], quaternion[3])
#     print(euler)

    IMU_Readings = bytearray(struct.pack("f", euler[0]))\
                   + bytearray(struct.pack("f", euler[1]))\
                   + bytearray(struct.pack("f", euler[2]))
#     print(textout)
    
#     textout = bytearray([0, 10, 20, 30, 40, 10, 20, 30, 40, 10, 20, 30, 40, 10, 20, 30, 40, 10, 20])
#     print(len(textout))'''
#     time.sleep(0.05)
#     ser.open()
#     textout = ser.read(19)
    
#     print(textout)

    '''if len(textout) == 19:
        for i in range(len(textout)):
            if (textout[i] == 65 and textout[(i + len(textout) - 1) % len(textout)] == 66):
                for z in range(len(textout)):
                    FSR_temp[z] = textout[(i+z) % len(textout)]'''
                
    mm1.seek(0)
    FSR =  mm1.read()
    unpack_FSR = struct.unpack("ffff",FSR[1:17])
    print('FSR from STM32: ',unpack_FSR)
#     unpack_FSR = struct.unpack("ffff",FSR)
#     print('Read from STM32:', unpack_FSR)

    #Joystick Data Read
    axis_left_h = joystick.get_axis(0)
    axis_left_v = joystick.get_axis(1)
#     print('axis_left_h', axis_left_h)
#     print('axis_left_v', axis_left_v)
    
    Axis_Readings = bytearray(struct.pack("f",axis_left_h)) + bytearray(struct.pack("f",axis_left_v))
    
    button_A = joystick.get_button(0)
    button_B = joystick.get_button(1)
    button_X = joystick.get_button(2)
    button_Y = joystick.get_button(3)
    button_up_left = joystick.get_button(4)
    button_up_right = joystick.get_button(5)
    Button_Readings = bytearray([button_Y, button_A, button_X, button_B, button_up_left, button_up_left, button_up_right, button_up_right])
#     print(len(data_to_Simulink))
    data_to_Simulink = distance_data + IMU_Readings + Axis_Readings + Button_Readings #+ FSR
#     print('data_to_Simulink: ', data_to_Simulink)

def Write_STM32():

    global relay_commands
    global motor_commands

    header = bytearray([83])
    terminators = bytearray([0, 55, 69])

    transmission_array = header + motor_commands + relay_commands + terminators

#     print(ser.isOpen())
#     print(ser.in_waiting)
#     ser.write(transmission_array)
#     print(ser.out_waiting)
#     ser.close()
    mm.seek(0)
    mm.write(transmission_array)
    print('transmission_array STM32:', list(transmission_array))

def Countdown_Timer():
    
    global countdown_flag
    global relay_commands
    
    try:
        if countdown_flag == 1:
            relay_commands = bytearray([200, 200])


        if countdown_flag == 0:
            relay_commands = bytearray([10, 10])

#         print(countdown_flag)
        countdown_flag = 0
        
    except:
        1
        
'''def velocity_cal():
    global dis1
    global dis2
    global dis3
    
    distance_back = ToF1.get_distance()
    time.sleep(0.001)
    distance_right = ToF2.get_distance()
    time.sleep(0.001)
    distance_down = ToF3.get_distance()
    time.sleep(0.001)
    distance_front = ToF4.get_distance()
    time.sleep(0.001)
    distance_left = ToF5.get_distance()
    time.sleep(0.001)
    
    print(distance_front,distance_back,distance_right,distance_left,distance_down)'''
    
def quaternion_to_euler_angle_vectorized1(w, x, y, z):
    ysqr = y * y

    t0 = +2.0 * (w * x + y * z)
    t1 = +1.0 - 2.0 * (x * x + ysqr)
    X = np.arctan2(t0, t1)

    t2 = +2.0 * (w * y - z * x)
    t2 = np.where(t2>+1.0,+1.0,t2)
#     t2 = +1.0 if t2 > +1.0 else t2

    t2 = np.where(t2<-1.0, -1.0, t2)
#     t2 = -1.0 if t2 < -1.0 else t2
    Y = np.arcsin(t2)

    t3 = +2.0 * (w * z + x * y)
    t4 = +1.0 - 2.0 * (ysqr + z * z)
    Z = np.arctan2(t3, t4)

    return X, Y, Z 
 
print("Started")


t1 = perpetualTimer (0.05, UDP_Transmit, 'UDP_Transmit')
t2 = perpetualTimer (0.01, UDP_Recieve, 'UDP_Recieve')
# t3 = perpetualTimer (0.01, Read_Sensors_Compose_Data, 'Read_Sensors_Compose_Data')
# t4 = perpetualTimer (0.01, Write_STM32, 'Write_STM32')
t5 = perpetualTimer (2, Countdown_Timer, 'Countdown_Timer')

t1.start()
t2.start()
# t3.start()
# t4.start()
t5.start()
print('timer started!')




