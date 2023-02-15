
export readstatus, readdevice, switchON, switchOFF
export setconnections, setcarrierfrequency, setcarrierduty

readdevice(dev) = begin 
	sleep(0.1)
	send(dev, :E)
	sleep(0.1)
	readavailable(dev.serial) |> print
end
readstatus(dev) = dev.status

switchON(dev, nums_on) = begin
	on_off = [n ∈ nums_on for n in 1:25 ]
	channels = haskey(dev.status, :connection_channels) ? 
							dev.status[:connection_channels] : fill(0, 25)
	send( dev, :C; channels, on_off)
	dev.status[:on_off_channels] = on_off
	dev.status
end
switchON(dev, T, nums_on) = begin
	@async begin
		sleep(T)
		switchOFF(dev, 1:25)
	end
	switchON(dev, nums_on)
end
switchOFF(dev, nums_off) = switchON(dev, filter(i->i∉nums_off, 1:25))

setconnections( dev, channels=fill(0,25) ) = begin
	channels = [channels; fill(0, 25-length(channels))]
	on_off = haskey(dev.status, :on_off_channels) ? 
					dev.status[:on_off_channels] : falses(25)
	send(dev, :C; channels, on_off)
	dev.status[:connection_channels] = channels
end
setconnections( dev, connections::Dict{Integer, Integer} ) = begin
end

setcarrierfrequency(dev,  frequency) = begin
	if haskey(dev.status, :carrier_duty) 
		send(dev, :A; frequency, duty=dev.status[:carrier_duty])
	else
		send(dev, :A; frequency )
	end
	dev.status[:carrier_frequency] = frequency
end

setcarrierduty(dev,  duty) = begin
	if haskey(dev.status, :carrier_frequency) 
		send(dev, :A; duty, fr=dev.status[:carrier_frequency])
	else
		send(dev, :A; duty )
	end
	dev.status[:carrier_duty] = duty
end
