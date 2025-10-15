/*
 * BME680_Sensor.c
 *
 *  Created on: Oct 13, 2025
 *      Author: Harlo
 */


#include "main.h"
#include <math.h>

extern ADC_HandleTypeDef hadc1;

float BME680_read_f(void)
{
	uint32_t sum = 0;	// variable to hold sum of data

	// Configure ADC
	ADC_ChannelConfTypeDef sConfig = {0};	// create ADC object
	HAL_ADC_Stop(&hadc1);	// stop reading from channel to switch to channel 2
	sConfig.Channel = ADC_CHANNEL_2;	// want to read from channel 2 --> BME680
	HAL_ADC_Start(&hadc1); 	// start reading from channel
	HAL_ADC_PollForConversion(&hadc1, HAL_MAX_DELAY);	// give ADC time to properly read sample

	for (int i = 0; i < 10; i++)	// take 10 samples
	{
		uint16_t data = HAL_ADC_GetValue(&hadc1);
		sum += data;
		HAL_Delay(2); // small delay to avoid reading the exact same sample
	}

	float avg = sum / 10.0f;	// average the total samples
	return avg;	// return the average
}
