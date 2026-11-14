print ("This is a “OS“ ")
#
e = ("Error!")
help_msg = ("echo , ver ,  exit , echo+ , echo- , echo*")
#
while True:
    a = input ("C:/ : ")
    if a == "ver":
        print ("V.0.1.3")
    elif a == "echo":
        print ("Done!")
        b = input ("echo ")
        print (b)
    elif a == "exit":
        break
    elif a == "help":
        print (help_msg)
    elif a == "echo+":
        and_1 = input ("1_+ : ")
        and_2 = input ("2_+ : ")
        and_end = float(and_1) + float(and_2)
        print (and_end)
    elif a == "echo-":
        umand_1 = input ("1_- : ") 
        umand_2 = input ("2_- : ") 
        umand_end = float(umand_1) - float(umand_2)
        if umand_end <= 0:
            print (e)
        else:
            print (umand_end)
    elif a == "echo*":
        uland_1 = input ("1_* : ")
        uland_2 = input ("2_* : ")
        uland_end = float(uland_1) * float(uland_2)
        if uland_end <= 0:
            print (e)
        else:
            print (uland_end)
    elif a == "echo/":
        uoand_1 = input ("1_/ : ")
        uoand_2 = input ("2_/ : ")
        uoand_2 = float(uoand_2)
        if uoand_2 == 0:
            print (e)
        else:
            uoand_end = float(uoand_1) / uoand_2
            print (uoand_end)
    else:
        print (e)
