#!/usr/bin/env python3
"""Store /camera/image_raw as a BGR NumPy array for OpenCV detection.

Run directly after sourcing ROS, or use the repository's camera.sh.
Override the topic with: --ros-args -p image_topic:=/other/image_raw
Requires rclpy, sensor_msgs, cv_bridge (ros-jazzy-cv-bridge).
"""

import rclpy
from cv_bridge import CvBridge, CvBridgeError
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy
from sensor_msgs.msg import Image


class ImageSubscriber(Node):
    def __init__(self):
        super().__init__('image_subscriber')
        topic = self.declare_parameter('image_topic', '/camera/image_raw').value
        self.bridge = CvBridge()
        self.latest_frame = None  # H x W x 3 uint8 NumPy array, BGR order.
        self.latest_header = None
        self.subscription = self.create_subscription(
            Image, topic, self.image_callback,
            QoSProfile(history=HistoryPolicy.KEEP_LAST, depth=1,
                       reliability=ReliabilityPolicy.BEST_EFFORT),
        )
        self.get_logger().info(f'Waiting for images on {topic}')

    def image_callback(self, message):
        try:
            frame = self.bridge.imgmsg_to_cv2(message, desired_encoding='bgr8')
        except CvBridgeError as error:
            self.get_logger().error(f'Image conversion failed: {error}')
            return
        first_frame = self.latest_frame is None
        self.latest_frame = frame
        self.latest_header = message.header
        if first_frame:
            self.get_logger().info(f'Received first image: {frame.shape}')
        # A writable copy lets detection modify pixels without changing latest_frame.
        self.detect(self.latest_frame.copy())

    def detect(self, frame):
        
        # TODO

        pass


def main(args=None):
    rclpy.init(args=args)
    node = ImageSubscriber()
    try:
        rclpy.spin(node)
    except (KeyboardInterrupt, ExternalShutdownException):
        pass
    finally:
        node.destroy_node()
        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
