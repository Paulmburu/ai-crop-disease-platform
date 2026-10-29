import numpy as np
import pytest

from crop_ml.threshold import choose_threshold


def test_picks_lowest_threshold_reaching_target():
    conf = np.array([0.55, 0.6, 0.7, 0.8, 0.9, 0.95])
    correct = np.array([False, False, True, True, True, True])
    choice = choose_threshold(conf, correct, target_precision=0.95)
    assert choice.threshold == pytest.approx(0.7)
    assert choice.precision == 1.0 and choice.coverage == pytest.approx(4 / 6)


def test_never_below_floor_even_if_everything_is_right():
    conf = np.array([0.4, 0.6, 0.9])
    choice = choose_threshold(conf, np.array([True, True, True]), floor=0.5)
    assert choice.threshold == 0.5 and choice.coverage == pytest.approx(2 / 3)


def test_unreachable_target_falls_back_to_most_selective():
    conf = np.array([0.6, 0.7, 0.9])
    choice = choose_threshold(conf, np.array([True, False, False]), target_precision=0.99)
    assert choice.threshold == pytest.approx(0.9) and choice.precision == 0.0


def test_empty_input_is_an_error():
    with pytest.raises(ValueError):
        choose_threshold(np.array([]), np.array([], dtype=bool))
