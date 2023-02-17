#: ####################################################
#:  struct
#: ####################################################

export _ch, _p

struct Channel; num end
Base.:*(n::Int, ::Type{Channel}) = Channel(n)
Base.:(:)( x::Channel, y::Channel ) = [Channel(n) for n in (x.num):(y.num)]

struct Port; num end
Base.:*(n::Int, ::Type{Port}) = Port(n)
Base.:(:)( x::Port, y::Port ) = [Port(n) for n in (x.num):(y.num)]

const _ch, _p = Channel, Port

#: ####################################################
#:  method
#: ####################################################

#= Aコマンド =# export setcarrierfrequency, setcarrierduty 
#= Bコマンド =# export setburstduty, setvolatge, setwavetype, setwavestep	
#= Cコマンド =# export switchON, switchOFF, setconnections, resetconnections
#= Eコマンド =# export readdevice 

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

setwavetype() = begin
	
end

setwavestep() = begin
	
end

setvolatge(dev, channel::Channel, voltage) = begin
	@assert voltage<90 "dangerous, voltage($voltage V) must be smaller than 90 V"
	@assert voltage<15 "dangerous, voltage($voltage V) must be smaller than 15 V"
	@assert channel ∈ (1_ch:4_ch) "the value of channel must be 1_ch ~ 4_ch"
	ch = channel.num
	V = voltage>60 ? 90 : voltage>30 ? 60 : 30
	P = (127 * voltage) ÷ V |> Int
	# duty = haskey(dev.status, :duty) ? 
							# dev.status[:duty] : fill(-1, 25)
	# type = haskey(dev.status, :type) ? 
							# dev.status[:type] : fill(-1, 25)
	# step = haskey(dev.status, :step) ? 
							# dev.status[:step] : fill(-1, 25)
	send( dev, :B; ch, V, P, duty=30, type=0, step=1 )
end

setvolatge(dev, (v1, v2, v3, v4)) = begin
	setvolatge(dev, 1_ch, v1)
	setvolatge(dev, 2_ch, v2)
	setvolatge(dev, 3_ch, v3)
	setvolatge(dev, 4_ch, v4)
end

#* Cコマンドのラッパー
switchON(dev, ports_on::AbstractVector{Port}) = begin
	on_off = [ n_p ∈ ports_on for n_p in 1_p:25_p ]
	connections = haskey(dev.status, :ports_connection) ? 
							dev.status[:ports_connection] : fill((-1_ch).num, 25)
	send( dev, :C; connections, on_off)
	dev.status[:ports_on_off] = on_off
	dev.status
end
switchON(dev, T, ports_on::AbstractVector{Port}) = begin
	@assert T < 10 "dangerous, stimulate time T must be smaller than 10 s"
	@async begin 
		sleep(T)
		switchOFF(dev)
	end
	switchON(dev, ports_on)
end
switchOFF(dev, ports_off::AbstractVector{Port}) = switchON(dev, filter( p->p∉ports_off, 1_p:25_p ))
switchOFF(dev) = switchOFF(dev, 1_p:25_p)

setconnections( dev, channels::AbstractVector{Channel} ) = begin
	@assert 0 ≤ length(channels) ≤ 25 
	connections = getproperty.([channels; fill(-1_ch, 25-length(channels))], :num)
	on_off = haskey(dev.status, :ports_on_off) ? 
					dev.status[:ports_on_off] : falses(25)
	send(dev, :C; connections, on_off)
	dev.status[:ports_connection] = connections
end
setconnections( dev, connection_pairs::Vector{Pair{Port, Channel}} ) = begin
	connections = haskey(dev.status, :ports_connection) ? 
									dev.status[:ports_connection] .*_ch  : fill(-1_ch, 25)
	for (p, ch) in connection_pairs
		connections[p.num] = ch
	end
	setconnections(dev, connections)
end
resetconnections( dev ) = setconnections( dev,fill(-1_ch, 25) )

#* Eコマンドのラッパー
readdevice(dev) = begin 
	sleep(0.1)
	send(dev, :E)
	sleep(0.1)
	readavailable(dev.serial) |> print
end
