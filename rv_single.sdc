# inform quartus that the clk port brings a 30MHz clock into our design so
	# that timing closure on our design can be analyzed

create_clock -name clk -period "30MHz" [get_ports clk]

# inform quartus that the gpio output port has no critical timing requirements
	# its a single output port driving an LED, there are no timing relationships
	# that are critical for this

set_false_path -from * -to [get_ports gpio_out]