
export readstatus, readdevice, switchON, switchOFF
export setconnections, setcarrierfrequency, setcarrierduty, setvolatge

#* Aコマンドのラッパー
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

#* Bコマンドのラッパー
setburstduty() = begin
	
end

setvolatge(dev, ch, voltage) = begin
	@assert voltage<90 "dangerous, voltage($voltage V) must be smaller than 90 V"
	@assert voltage<15 "dangerous, voltage($voltage V) must be smaller than 90 V"
	V = voltage>60 ? 90 : voltage>30 ? 60 : 30
	P = (127 * voltage) ÷ V
	# P*V/127>15 && @warn "dangerous, voltage($voltage V) may be too high"
	# duty = haskey(dev.status, :ports_connection) ? 
							# dev.status[:ports_connection] : fill(-1, 25)
	send( dev, :B; ch, V, P, duty=30, type=0, step=1)
end

setvolatge(dev, voltages) = begin
	@assert length(voltages) == 4 "voltages is must 4 elements"
	for (i,v) in enumerate(voltages)
		setvolatge(dev, i, v)
	end
end

#* Cコマンドのラッパー
switchON(dev, ports_on) = begin
	on_off = [n ∈ ports_on for n in 1:25 ]
	connections = haskey(dev.status, :ports_connection) ? 
							dev.status[:ports_connection] : fill(-1, 25)
	send( dev, :C; connections, on_off)
	dev.status[:ports_on_off] = on_off
	dev.status
end
switchON(dev, T, ports_on) = begin
	@assert T < 10 "dangerous, stimulate time T must be smaller than 10 s"
	@async begin 
		sleep(T)
		switchOFF(dev, 1:25)
	end
	switchON(dev, ports_on)
end
switchOFF(dev, ports_off) = switchON(dev, filter(i->i∉ports_off, 1:25))

setconnections( dev, connections=fill(-1,25) ) = begin
	@assert 0 ≤ length(connections) ≤ 25 
	connections = [connections; fill(-1, 25-length(connections))]
	on_off = haskey(dev.status, :ports_on_off) ? 
					dev.status[:ports_on_off] : falses(25)
	send(dev, :C; connections, on_off)
	dev.status[:ports_connection] = connections
end
setconnections( dev, connections::Vector{Pair{Int, Int}} ) = begin
	error()
	dic = Dict(connections)
	connections = fill(1,25)
	setconnections(dev, connections)
end

#* Eコマンドのラッパー
readdevice(dev) = begin 
	sleep(0.1)
	send(dev, :E)
	sleep(0.1)
	readavailable(dev.serial) |> print
end
