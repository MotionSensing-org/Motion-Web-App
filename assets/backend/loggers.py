import datetime
import logging

now = datetime.datetime.now()
log_file = str(now.date()) \
           + "--" \
           + str(now.time().hour) \
           + "-" \
           + str(now.time().minute) \
           + "-" \
           + str(now.time().second) \
           + "--backend.log"

formatter = logging.Formatter('%(asctime)s [%(levelname)s] - %(message)s')


#############################
# DEBUG
#############################

debug_logger = logging.getLogger('debug')

# Set the logging level (e.g., logging.DEBUG, logging.INFO, logging.WARNING, etc.)
debug_logger.setLevel(logging.DEBUG)

# Create a file handler and set its level to the same as the logger
debug_handler = logging.FileHandler(log_file)
debug_handler.setLevel(logging.DEBUG)
debug_handler.setFormatter(formatter)

# Add the handler to the logger
debug_logger.addHandler(debug_handler)


#############################
# INFO
#############################

info_logger = logging.getLogger('info')

# Set the logging level (e.g., logging.DEBUG, logging.INFO, logging.WARNING, etc.)
info_logger.setLevel(logging.INFO)

# Create a file handler and set its level to the same as the logger
info_handler = logging.FileHandler(log_file)
info_handler.setLevel(logging.INFO)
info_handler.setFormatter(formatter)

# Add the handler to the logger
info_logger.addHandler(info_handler)


#############################
# ERROR
#############################

error_logger = logging.getLogger('error')

# Set the logging level (e.g., logging.DEBUG, logging.INFO, logging.WARNING, etc.)
error_logger.setLevel(logging.ERROR)

# Create a file handler and set its level to the same as the logger
error_handler = logging.FileHandler(log_file)
error_handler.setLevel(logging.ERROR)
error_handler.setFormatter(formatter)

# Add the handler to the logger
error_logger.addHandler(error_handler)