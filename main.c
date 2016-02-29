/*
STM32F10X_MD
USE_STDPERIPH_DRIVER
shouchuang keji's board -- stm32f103c8
GPIOA11 --> LED
*/

#include "stm32f10x.h"
#include "usart.h"

uint16_t received_data =0;
uint16_t data =0;
void GPIOA_11(void);

int main(void)
{
    RCC_Configuration();
    GPIO_Configuration();
    USART2_Config();
    GPIOA_11();				/* LED's GPIO */
    while(1)
    {
      GPIO_SetBits(GPIOA, GPIO_Pin_11);
      while(USART_GetFlagStatus(USART2, USART_FLAG_RXNE) == RESET);     /* wait for data */
      received_data = USART_ReceiveData(USART2);
      
      GPIO_ResetBits(GPIOA, GPIO_Pin_11);
      USART_SendData(USART2, received_data);
      while(USART_GetFlagStatus(USART2, USART_FLAG_TC) == RESET);       /* wait for data Transmission Complete */
    }
}

void GPIOA_11(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* GPIOD Periph clock enable */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);

  /* Configure PD0 and PD2 in output pushpull mode */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
}

void USART2_IRQHandler(void)
{
  
  if(USART_GetITStatus(USART2, USART_IT_RXNE) != RESET)
  {
    /* Read one byte from the receive data register */
    data = USART_ReceiveData(USART2);
  }
}
