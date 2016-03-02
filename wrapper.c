
extern int lab7(void);
extern int interrupt_init(void);
extern int uart_init(void);
extern int pin_connect_block(void);
extern int pin_direction(void);

int main(){
	interrupt_init();
	uart_init();
	pin_direction();
	pin_connect_block();
	lab7();
}	
