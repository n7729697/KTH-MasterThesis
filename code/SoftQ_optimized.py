import pygame  # A library for handling joystick input.
import socket  # Provides networking functionality for UDP communication.
import struct  # Allows for the packing and unpacking of binary data.
from perpetualtimer import *  # A custom module for creating perpetual timers.
import adafruit_bno055 as bno  # A library for interfacing with the BNO055 IMU (Inertial Measurement Unit).
import board  # Provides an interface to the Raspberry Pi's GPIO pins.
import qwiic  # A library for interacting with the ToF (Time-of-Flight) sensors.
import RPi.GPIO as GPIO  # A library for controlling the Raspberry Pi's GPIO pins.
import serial  # Allows for serial communication with the STM32 microcontroller.
import numpy as np  # A library for numerical operations.
import time  # Provides functions for time-related operations.
import threading  # Allows for multi-threading support.
import logging  # Provides logging capabilities for debugging and error tracking.
from dataclasses import dataclass
from typing import Optional, Any, Tuple

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# ToF_12345=front,back,left,right,down
# XSHUT = [18, 20, 21, 16, 7]
XSHUT = [16, 18, 7, 20, 21]
I2C = [0x21, 0x22, 0x23, 0x24, 0x25]
regs=[45, 0, 25, 0, 198, 255, 155, 254, 156, 255, 88, 255, 0, 0, 2, 0, 253, 255, 232, 3, 51, 2]
remap=(1,0,2,0,1,0)

# UDP Transmission
# HOST0 = Commands
# HOST1 = Feedback
#HOST1 = '192.168.1.33'  # Standard loopback interface address (localhost)
HOST1 = '0.0.0.0'
PORT1 = 1999

#HOST2 = '192.168.1.35'  # Standard loopback interface address (localhost)
HOST2 = '0.0.0.0'
PORT2 = 2023       # Port to listen on (non-privileged ports are > 1023)

#HOST3 is joystick back Simulink
HOST3 = '0.0.0.0'
PORT3 = 8888

#HOST4 is joystick to Simulink
HOST4 = '0.0.0.0'
PORT4 = 6666

@dataclass
class SensorData:
    """
    Represents sensor data including Time-of-Flight (ToF), acceleration, quaternion, Euler angles, 
    and force-sensitive resistors (FSR).
    
    Attributes:
        _tof: Tuple of optional values representing Time-of-Flight sensor readings.
        _acc: Tuple of optional float values representing acceleration measurements.
        _quat: Tuple of optional float values representing quaternion data.
        _euler: Tuple of optional float values representing Euler angles.
        _fsr: Tuple of optional float values representing FSR readings.
        offset: Tuple of optional float values representing offsets for euler data.
    """

    distance: Tuple[Optional[Any], 'Optional[Any]', 'Optional[Any]', 'Optional[Any]', 'Optional[Any]']
    acc: Tuple['Optional[float]', 'Optional[float]', 'Optional[float]']
    quat: Tuple['Optional[float]', 'Optional[float]', 'Optional[float]', 'Optional[float]']
    euler: Tuple['Optional[float]', 'Optional[float]', 'Optional[float]']
    fsr: Tuple['Optional[float]', 'Optional[float]', 'Optional[float]', 'Optional[float]']
    offset = Tuple[Optional[float], Optional[float], Optional[float]]

    def __init__(
        self,
        tof: Tuple[Optional[Any], Optional[Any], Optional[Any], Optional[Any], Optional[Any]] = (None, None, None, None, None),
        acc: Tuple[Optional[float], Optional[float], Optional[float]] = (None, None, None),
        quat: Tuple[Optional[float], Optional[float], Optional[float], Optional[float]] = (None, None, None, None),
        fsr: Tuple[Optional[float], Optional[float], Optional[float], Optional[float]] = (None, None, None, None),
        euler: Tuple[Optional[float], Optional[float], Optional[float]] = (None, None, None),
        offset: Tuple[Optional[float], Optional[float], Optional[float]] = (None, None, None)
    ):
        self.tof = tof
        self.acc = acc
        self.quat = quat
        self.fsr = fsr
        self.euler = euler
        self.offset = offset

    def update_tof(self, new_tof: Tuple[Optional[Any], Optional[Any], Optional[Any], Optional[Any], Optional[Any]]):
        if len(new_tof) == 19:
            self.tof = new_tof
        else:
            raise ValueError("Received data length is wrong")
        

    def update_acc(self, new_acc: Tuple[Optional[float], Optional[float], Optional[float]]):
        self.acc = new_acc

    def update_quat(self, new_quat: Tuple[Optional[float], Optional[float], Optional[float], Optional[float]]):
        self.quat = new_quat
        self.euler = self.quaternion_to_euler_angle_vectorized(self.quat)

    def update_fsr(self, new_fsr: Tuple[Optional[float], Optional[float], Optional[float], Optional[float]]):
        self.fsr = new_fsr

    def quaternion_to_euler_angle_vectorized(self):
        """
        Convert quaternion representation to Euler angles.

        This method calculates the Euler angles (roll, pitch, yaw) from the quaternion 
        representation. It assumes that the quaternion values are stored in the '_quat' 
        attribute. The method also takes into account the offset values stored 
        in the 'offset' attribute.

        Returns:
            Tuple of float values representing the Euler angles (roll, pitch, yaw).
        """
        if self.quat is not None:
            w, x, y, z = self.quat
        else:
            w, x, y, z = [0, 0, 0, 0]

        ysqr = y * y

        t0 = +2.0 * (w * x + y * z)
        t1 = +1.0 - 2.0 * (x * x + ysqr)
        X = np.arctan2(t0, t1)-self.offset[0]

        t2 = +2.0 * (w * y - z * x)
        t2 = np.where(t2>+1.0,+1.0,t2)
    #     t2 = +1.0 if t2 > +1.0 else t2

        t2 = np.where(t2<-1.0, -1.0, t2)
    #     t2 = -1.0 if t2 < -1.0 else t2
        Y = np.arcsin(t2)-self.offset[1]

        t3 = +2.0 * (w * z + x * y)
        t4 = +1.0 - 2.0 * (ysqr + z * z)
        Z = np.arctan2(t3, t4)-self.offset[2]

        return X, Y, Z

@dataclass
class SofQData:
    motor_commands: bytearray
    relay_commands: bytearray
    udp_host_port: Any
    header = bytearray([83]) # STM32 header
    terminators = bytearray([0, 55, 69]) # STM32 terminators

    def __init__(self, udp_host_port.to,udp_host_port.back):
        self.motor_commands = bytearray()
        self.relay_commands = bytearray()
        self.udp_host_port.to = udp_host_port.to
        self.udp_host_port.back = udp_host_port.back
        self.header = bytearray([83])  # STM32 header
        self.terminators = bytearray([0, 55, 69])  # STM32 terminators

    def update_motor_commands(self, new_commands: bytearray):
        if len(new_commands) == 12:
            self.motor_commands = new_commands
        else:
            raise ValueError("Received motor cmds are wrong")

    def update_relay_commands(self, new_commands: bytearray):
        self.relay_commands = new_commands

    def get_data_to_stm32(self):
        """
        Get the data to be sent to STM32 microcontroller.

        This method combines the header, motor commands, relay commands, and terminators into 
        a single data packet to be sent to the STM32 microcontroller.

        Returns:
            bytearray: The data packet to be sent to STM32 as a bytearray.
        """
        data_to_stm32 = self.header + self.motor_commands + self.relay_commands + self.terminators
        if len(data_to_stm32) != 18:
                raise ValueError("Motor command length is wrong")
        return data_to_stm32

class SoftQ:
    """
    - Initialization: Sets up the necessary components, such as sensors, communication interfaces, 
    and GPIO pins.
    - Sensor Reading: Reads data from the ToF sensors, IMU, and joystick (if enabled).
    - Data Composition: Composes the data obtained from the sensors into a format suitable for 
    transmission to a remote device (Simulink).
    - Communication: Transmits the sensor data to Simulink via UDP communication.
    - Control: Receives control commands from Simulink and updates the motor commands accordingly.
    - Countdown Timer: Implements a countdown timer that sets a flag to activate or deactivate 
    certain functionality at specific intervals.
    - Cleanup: Properly closes connections and cleans up resources when the program terminates.
    """
    def __init__(self, useJoy=False):
        # communication and event object
        self._countdown_flag = False
        self.use_joystick = useJoy
        self.lock = threading.Lock()

        # Initialize the joysticks.
        if useJoy:
            self.data = SofQData((HOST3, PORT3),(HOST4, PORT4))
            self.initialize_joystick()
        else:
            self.data = SofQData((HOST1, PORT1),(HOST2, PORT2))

        # ToF setup
        self.tof=[None for _ in range(5)]
        self.tof_setup()
        self.imu_setup()
        self.serial_setup()
        
        # SoftQ communication data
        motor_commands_init = bytearray([90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90]) # 12
        relay_commands_init = bytearray([10, 10]) # 10, 10 or 200, 200
        self.data.update_motor_commands(motor_commands_init)
        self.data.update_relay_commands(relay_commands_init)

        # Sensor data
        distance_init = self.read_dis()
        acc_init = [0.0, 0.0, 0.0]
        quat_init = [0.0, 0.0, 0.0, 0.0]
        euler_init = [0.0, 0.0, 0.0]
        fsr_init = [0.0, 0.0, 0.0, 0.0]

        self.sensor_data = SensorData(distance_init,acc_init,quat_init,fsr_init,euler_init)

    def start(self):
        timer_com_stm32 = perpetualTimer(0.05, self.Write_Read_STM32_thread,'Write_Read_STM32')
        timer_write_simulink = perpetualTimer(0.05, self.UDP_Transmit, 'UDP_Transmit')
        timer_listen_simulink = perpetualTimer(0.01, self.UDP_Recieve, 'UDP_Recieve')
        timer_countdown = perpetualTimer(2, self.Countdown_Timer, 'Countdown_Timer')
        
        timer_write_simulink.start()
        timer_listen_simulink.start()
        timer_com_stm32.start()
        timer_countdown.start()
    
    def UDP_Transmit(self):
        self.sensor_data.update_tof(self.read_dis())  # it has to excute longer time so listout
        self.sensor_data.update_quat(self.IMU.quaternion)
        data_to_Simulink = self.get_data_to_simulink()
        try:
            self.sock2.sendto(data_to_Simulink, self.data.udp_host_port.to)
        except:
            logging.error("UDP transmitted to Simulink failed at : %d\n",list(data_to_Simulink))

    def UDP_Recieve(self):
        try:
            data_from_simulink = self.sock1.recv(1024)
        except:
            logging.error("UDP received from Simulink failed at %d\n",list(data_from_simulink))

        self.data.update_motor_commands(data_from_simulink) 
        self.set_countdown_flag(True)
        self.data.update_relay_commands(bytearray([200, 200])) 

    def Write_Read_STM32_thread(self):
        try:
            data_to_stm32 = self.data.get_data_to_stm32()
            logging.debug("data_to_stm32: %s", list(data_to_stm32))
            with self.lock:
                self.ser.write(data_to_stm32)
                data_from_stm32 = self.ser.read(19)

            self.sensor_data
            

            if data_from_stm32[-1] != 66:
                raise ValueError("Received data format is wrong")
            fsr = struct.unpack("ffff", data_from_stm32[1:17])
            self.sensor_data.fsr=fsr
            logging.debug('FSR from STM32: %s', fsr)
        except ValueError as error:
            logging.error(str(error))

    
    def Countdown_Timer(self):
        try:
            if self.get_countdown_flag() == True:
                self.set_countdown_flag(bytearray([200, 200]))

            else:
                self.set_relay_commands(bytearray([10, 10]))

            self.set_countdown_flag(False)
        except:
            logging.error('countdown_flag is wrong at Countdown_Timer: %s', self.get_countdown_flag())
    
    def imucali(self):
        while self.imu.calibrated is not True:
            print(self.imu.acceleration, self.imu.calibration_status)
            time.sleep(1)
        
        input("Press enter to continue...")
        

    def clear(self):
        '''
        Only the ToF can not be cleared, so this function need more modification
        '''
        for tof in self.tof:
            if tof is not None:
                tof.stop_ranging()
        GPIO.cleanup()
        
        if self.i2c is not None:
            self.imu.i2c_device.i2c.deinit()
            self.i2c.deinit()
        
        if self.ser is not None:
            self.ser.close()
            
        if self.sock1 is not None:
            self.sock1.close()
            
        if self.sock2 is not None:
            self.sock2.close()
        
        if self.joystick is not None:
            pygame.joystick.quit()
        
        self.tof = [None for _ in range(5)]
        self.i2c = None
        self.imu = None
        self.ser = None
        self.sock1 = None
        self.sock2 = None
        self.joystick = None


    def get_data_to_simulink(self):
        """
        Get the data to be sent to Simulink.

        This method prepares the data to be sent to Simulink based on the specified flag 'use_joystick'.
        If 'use_joystick' is True, it includes joystick readings in the data packet along with distance, 
        euler angles, and button readings. If 'use_joystick' is False, it includes distance, euler angles, 
        acceleration, and force-sensitive resistor (FSR) readings in the data packet.

        Returns:
            bytearray: The data packet to be sent to Simulink as a bytearray.
        """
        if self.use_joystick:
            axis_readings, button_readings = self.read_joystick()
            return self.encode_arrays(self.sensor_data.distance, self.sensor_data.euler, \
                                      axis_readings) + bytearray(button_readings)
        else:
            return self.encode_arrays(self.sensor_data.distance, self.sensor_data.euler, \
                                      self.sensor_data.acc) + self.sensor_data.fsr

    def initialize_joystick(self):
        """
        Initializes the joystick module and connects to the first available joystick.
        """
        try:
            pygame.init()
            joystick_count = pygame.joystick.get_count()
            if joystick_count == 0:
                raise pygame.error("No joysticks found.")
            joystick = pygame.joystick.Joystick(0)
            joystick.init()
            logging.info('Joysticks online!')
        except pygame.error as err:
            logging.error('Error initializing joystick: %s', err)

    def serial_setup(self):
        '''
        Sets up a serial connection and creates socket objects.

        This function initializes a serial connection with the specified parameters 
        and creates two socket objects for communication. If any errors occur during 
        the initialization, appropriate error messages are logged.

        Args:
            self: The instance of the class.

        Returns:
            None
        '''
        #Serial Setup
        try:
            self.ser = serial.Serial("/dev/ttyAMA0", 115200, timeout = 0.01)
            self.ser.flushInput()
            self.ser.flushOutput()
            time.sleep(1)
            print('Serial connected to STM32!')
        except Exception as error:
            logging.error('Error Initializing serial connection! Error: %s', str(error))
        self.Write_Read_STM32_thread()

        try:
            self.sock1 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock2 = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        except Exception as error:
            logging.error('Socket to simulink failed! Error: %s', str(error))

    def tof_setup(self):
        """
        Set up Time-of-Flight (ToF) sensors using XSHUT and I2C pin configurations.

        Args:
            XSHUT (list): List of XSHUT pin numbers corresponding to the ToF sensors.
            i2c (list): List of I2C addresses corresponding to the ToF sensors.

        Returns:
            Union[bool, int]: Returns True if all ToF sensors are successfully set up. 
                            Returns the index (int) of the ToF sensor that failed to 
                            initialize if an error occurs.
        """
        # GPIO reset
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(XSHUT, GPIO.OUT)
        GPIO.cleanup()
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(XSHUT, GPIO.OUT)
        GPIO.output(XSHUT, GPIO.LOW)
        try:
            for idx, (i, j) in enumerate(zip(XSHUT, I2C)):
                GPIO.output(i, GPIO.HIGH)
                time.sleep(0.1)
                self.tof[idx] = qwiic.QwiicVL53L1X()
                self.tof[idx].sensor_init()
                time.sleep(0.2)
                self.tof[idx].set_i2c_address(j)
                if self.tof[idx].sensor_init() is None:
                    print("ToF sensor", idx+1, "online!")
                else:
                    logging.error("ToF %d not working!", idx+1)
                self.tof[idx].start_ranging()
        except (qwiic.QwiicException, IOError) as error:
            logging.error('ToF sensor is not working! Error: %s', str(error))

    def imu_setup(self):
        """
    Set up the IMU (Inertial Measurement Unit).

    This method initializes the IMU by attempting to connect to it repeatedly 
    for a maximum number of attempts. It assumes that the IMU object is stored 
    in the .imu' attribute. The maximum number of attempts can be adjusted 
    by modifying the 'max_attempts' variable. The method also handles exceptions 
    that may occur during the initialization process and logs appropriate error messages.

    Returns:
        bool: True if the IMU is successfully initialized, False otherwise.
    """
        # IMU SETUP
        self.i2c = board.I2C()
        max_attempts = 100

        for i in range(max_attempts):
            try:
                self.imu = bno.BNO055_I2C(i2c=self.i2c)
                print('IMU online!')
                break  # Successful connection, break out of the loop
            except Exception as error:
                print('Error Initializing IMU! Keep trying...', i + 1, 'times!')
                if i == max_attempts:
                    logging.error('Initializing IMU failed! Try again later! Error: %s',str(error))
                time.sleep(0.05)
                self.i2c = board.I2C()
                self.axis_remap(remap)
                self.imu_resume(regs)

    def read_dis(self):
        # front, back, left, right, back
        distance = [0 for _ in range(len(self.tof))]
        for i in range(len(self.tof)):
            distance[i] = self.tof[i].get_distance()
            time.sleep(0.001)
        self.sensor_data.distance=distance
        return distance

    def read_set_offsets(self, boolIn=False):
        if boolIn is True:
            # Read user input
            x_offset = float(input("Enter the x offset: "))
            y_offset = float(input("Enter the y offset: "))
            z_offset = float(input("Enter the z offset: "))
        else:
            x_offset, y_offset, z_offset = self.sensor_data.quaternion_to_euler_angle_vectorized(self.imu.quaternion) 

        self.offset=[x_offset, y_offset, z_offset]
        # Return the assigned offsets
        return self.offset
    
    def imu_resume(self, regs):
        # write previous calibration
        current_mode = self.imu._read_register(bno._MODE_REGISTER)
        self.imu.mode=bno.CONFIG_MODE
        for i in range(0x55,0x6A+1,1):
            self.imu._write_register(i,regs[i-0x55])
    
        self.imu._write_register(bno._MODE_REGISTER, current_mode)
        time.sleep(2)
        print('IMU retracked to previous calibration data', self.imu.calibration_status)
    
    def axis_remap(self, remap):
        """Pass a tuple consisting of x, y, z, x_sign, y-sign, and z_sign.

        Set axis remap for each axis.  The x, y, z parameter values should
        be set to one of AXIS_REMAP_X (0x00), AXIS_REMAP_Y (0x01), or
        AXIS_REMAP_Z (0x02) and will change the BNO's axis to represent another
        axis.  Note that two axises cannot be mapped to the same axis, so the
        x, y, z params should be a unique combination of AXIS_REMAP_X,
        AXIS_REMAP_Y, AXIS_REMAP_Z values.
        The x_sign, y_sign, z_sign values represent if the axis should be
        positive or negative (inverted). See section 3.4 of the datasheet for
        information on the proper settings for each possible orientation of
        the chip.
        """
        x, y, z, x_sign, y_sign, z_sign = remap
        # Switch to configuration mode. Necessary to remap axes
        current_mode = self.imu._read_register(bno._MODE_REGISTER)
        self.imu.mode = bno.CONFIG_MODE
        # Set the axis remap register value.
        map_config = 0x00
        map_config |= (z & 0x03) << 4
        map_config |= (y & 0x03) << 2
        map_config |= x & 0x03
        self.imu._write_register(bno._AXIS_MAP_CONFIG_REGISTER, map_config)
        # Set the axis remap sign register value.
        sign_config = 0x00
        sign_config |= (x_sign & 0x01) << 2
        sign_config |= (y_sign & 0x01) << 1
        sign_config |= z_sign & 0x01
        self.imu._write_register(bno._AXIS_MAP_SIGN_REGISTER, sign_config)
        # Go back to normal operation mode.
        self.imu._write_register(bno._MODE_REGISTER, current_mode)
        print('IMU remap to', hex(map_config),hex(sign_config))

    def encode_arrays(self, data1, data2=b'', data3=b'', data4=b'', data5=b'',data6=b'',data7=b''):
        """
        Encode arrays of data into a single bytearray.

        This method encodes multiple arrays of data into a single bytearray, using 
        the `struct.pack` function. Each data array is packed into the bytearray using 
        the format string 'f' to represent floating-point values. The resulting bytearray 
        contains the encoded data from all the input arrays in the specified order.

        Args:
            data1 (iterable): The first array of data to encode.
            data2 (iterable, optional): The second array of data to encode. Defaults to an empty bytearray.
            data3 (iterable, optional): The third array of data to encode. Defaults to an empty bytearray.
            data4 (iterable, optional): The fourth array of data to encode. Defaults to an empty bytearray.
            data5 (iterable, optional): The fifth array of data to encode. Defaults to an empty bytearray.
            data6 (iterable, optional): The sixth array of data to encode. Defaults to an empty bytearray.
            data7 (iterable, optional): The seventh array of data to encode. Defaults to an empty bytearray.

        Returns:
            bytearray: The encoded data as a single bytearray.
    """
        data_encoded = bytearray()
        data_encoded.extend(struct.pack(f'{len(data1)}f', *data1))
        data_encoded.extend(struct.pack(f'{len(data2)}f', *data2))
        data_encoded.extend(struct.pack(f'{len(data3)}f', *data3))
        data_encoded.extend(struct.pack(f'{len(data4)}f', *data4))
        data_encoded.extend(struct.pack(f'{len(data5)}f', *data5))
        data_encoded.extend(struct.pack(f'{len(data6)}f', *data6))
        data_encoded.extend(struct.pack(f'{len(data7)}f', *data7))
        return data_encoded
    
    def get_countdown_flag(self):
        return self._countdown_flag


    def set_countdown_flag(self, countdown_flag):
        self._countdown_flag = bool(countdown_flag)

    def read_joystick(self):
        """
        Read joystick inputs and return the axis and button readings.

        This method initializes the joystick, reads the axis and button values, and returns them 
        as lists. The axis readings are obtained from axis 0 and 1, and the button readings are 
        obtained from buttons 0 to 7.

        axis_left_h = joystick.get_axis(0)
        axis_left_v = joystick.get_axis(1)
        button_A = joystick.get_button(0)
        button_B = joystick.get_button(1)
        button_X = joystick.get_button(2)
        button_Y = joystick.get_button(3)
        button_up_left = joystick.get_button(4)
        button_up_right = joystick.get_button(5)

        Returns:
            tuple: A tuple containing the axis readings (list) and button readings (list).
        """
        button_readings = [None for _ in range(8)]
        axis_readings = [None for _ in range(2)]
        pygame.event.get()
        joystick = pygame.joystick.Joystick(0)
        joystick.init()
        axis_readings=[joystick.get_axis(0), joystick.get_axis(1)]
        button_readings = [joystick.get_button(3), joystick.get_button(0),\
                            joystick.get_button(2), joystick.get_button(1),\
                            joystick.get_button(4), joystick.get_button(5),\
                            joystick.get_button(6), joystick.get_button(7)]
        return axis_readings, button_readings

if __name__ == '__main__':
    robot=SoftQ()
    robot.setup()
    robot.start() 