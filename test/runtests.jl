using Test
using ElectroStimulatorControllers

function AAA()
	d = Stimulator("COM4")
	send(d,:E)
	t_start = time()
	t = time() - t_start
	while t < 10
		t = time() - t_start
		s = 26 + 4sin(1.5*2π * t/10)
		send(d,:B, ch=0, P=trunc(Int,s))
		sleep(0.01)
	end
	send(d,:B, ch=0, P=trunc(Int,10))
	d |> finalize
end

function BBB()
	d = Stimulator("COM4")
	send(d,:E)
	t_start = time()
	t = time() - t_start
	s=20
	while t < 10
		t = time() - t_start
		s = readline()=="e" ? s+1 : s-1
		send(d,:B, ch=0, P=trunc(Int,s))
		sleep(0.01)
	end
	send(d,:B, ch=0, P=trunc(Int,10))
	d |> finalize
end

