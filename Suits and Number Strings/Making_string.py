from PIL import Image
import numpy as np
import cv2
import PIL



#img = Image.open('new_heartX.png')
#img = img.convert("RGB")
#ary = np.array(img)
#rec = np.empty_like(ary)


#image_in = cv2.imread('new_heartX.png')
#image_new = np.ones(image_in.shape[:A], dtype="uint8") * 255
#im = Image.open('new_heartX.png')


#img = Image.open('new_heart2.png')
#img = img.convert("RGB")
#ary = np.array(img)
#rec = np.empty_like(ary)


#im= Image.fromarray(rec*255)

#img = Image.open('new_heartX.png')
#img = img.convert("RGB")
#ary = np.array(img)
#rec = np.empty_like(ary)
##im= Image.fromarray(rec*255)
##im.save("new_heart.png")



img = Image.open('K.png')#change this
img = img.resize((16,16))
img.save("K.png") # change this
img = img.convert("RGB")
ary = np.array(img)
rec = np.empty_like(ary)

for x in range(len(ary)):
    for y in range(len(ary[x])):
        for z in range(ary[x][y].size):
            #print(ary[x][y][z])
            if(ary[x][y][z] > 127):
                rec[x][y][z]  = 1
            else:
                rec[x][y][z] = 0

im= PIL.Image.fromarray(rec*255)
im.save("pic10.png")# change this



out = ""
image_in = cv2.imread('K.png') # insert picture here
image_new = np.ones(image_in.shape[:2], dtype="uint8") * 255
for i in range(image_in.shape[0]):
    for j in range(image_in.shape[1]):
        #print(image_in[i,j].tolist())
        temp = image_in[i,j].tolist()
        for x in range(len(temp)):
            if(temp[x] == 255):
                out += "1"
            else:
                out+= "0"
print(out)
print(rec)
l = []
outArr=[]
final = []
for temp in range(len(out)):
    l.append(int(out[temp]))
    if(len(l)%3 ==0):
        outArr.append(l)
        l=[]
        if(len(outArr)%16 ==0):
            final.append(outArr)
            outArr = []
final = np.array(final)

im2= PIL.Image.fromarray(final*255)
im2.save("pic" + "K" + ".png")# change this
f = open("K.txt", "w") #change this
f.write(out)
f.close()