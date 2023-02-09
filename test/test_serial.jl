#  julia ver ゆうても pyserial のラップらしいが...
using SerialPorts	

ser = SerialPort("COM4", 230400)

write(ser, "\x02E\x03")
readavailable(ser) |> print
write(ser, "\x02A,02000,100,\x03")
close(ser)


# PyCall ver
using PyCall
@pyimport serial

@pywith serial.Serial("COM4",230400,timeout=0.1) as s begin
	println("connect success")
	command=pybytes("\x02E\x03")
	@show command
	s.write(command)
	sleep(0.001) #これがないせいで死んでいた
	s.read_all() |> print
end
