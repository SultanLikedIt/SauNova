import logging


def get_logger(name=__name__, level=logging.INFO):
    logger = logging.getLogger(name)
    if logger.hasHandlers():  # Prevent adding multiple handlers
        return logger

    logger.setLevel(level)
    ch = logging.StreamHandler()
    ch.setLevel(level)
    formatter = logging.Formatter('[%(levelname)s] %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger