/*************************************
 *@file		: usart.h
 *@brief 	: DMA and USART's configuration
 *@time		: 2014/08/22
 *@author	: jom 
*************************************/
#ifndef __USART_H
#define __USART_H

#include "stm32f10x.h"

void RCC_Configuration(void);
void GPIO_Configuration(void);
void USART2_Config(void);
void NVIC_Configuration(void);
void SysTick_Init(void);

#endif
