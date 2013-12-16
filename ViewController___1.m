//
//  ViewController.m
//  PlayPCM
//
//  Created by hanchao on 13-11-21.
//  Copyright (c) 2013年 hanchao. All rights reserved.
//

#import "ViewController.h"

#import <stdio.h>

@interface ViewController ()

@property (nonatomic,assign) NSInteger freqNum;

@end

#define SAMPLE_RATE             44100                                                    //采样频率
#define BB_SEMITONE 			1.05946311
#define BB_BASEFREQUENCY		1760
#define BB_CHARACTERS			"0123456789abcdefghijklmnopqrstuv"
#define BB_THRESHOLD            16
#define BB_HEADER_0             17
#define BB_HEADER_1             19
#define DURATION				0.0872 // seconds 0.1744//
#define MAX_VOLUME              0.5
static float frequencies[32];

static NSData *d;

static NSMutableData *wavData;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(IBAction)sliderEvent:(UISlider *)slider
{
    self.freqNum = (NSInteger)slider.value;
	self.freqlabel.text = [NSString stringWithFormat:@"%d",(NSInteger)slider.value];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)playAction:(id)sender
{
    int freqs[20] = {17, 19, 19, 3, 1, 30, 26, 26, 14, 16, 23, 5, 12, 19, 10, 3, 15, 13, 29, 23};
    
    NSLog(@"%lu",sizeof(freqs));
    
    makeChirp(freqs, sizeof(freqs)/sizeof(freqs[0]), DURATION, SAMPLE_RATE, 16);
    
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:wavData
                                                     error:&error];
    
    if (error) {
        NSLog(@"error....%@",[error localizedDescription]);
    }else{
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
    }

    [self.audioPlayer play];

}

void makeChirp(int freqArray[], int freqArrayLength, double duration_secs, long sample_rate, int bits_persample) {
    
    //定义buffer总长度
    long len_array = (long)(duration_secs * sample_rate * freqArrayLength);
	Float32 buffer[len_array];
    memset(buffer, 0, sizeof(buffer));

    double theta = 0;
    int idx = 0;
    for (int i=0; i<freqArrayLength; i++) {
        unsigned int freq;
        num_to_freq(freqArray[i],&freq);
        
        double theta_increment = 2.0 * M_PI * freq / sample_rate;
        
        // Generate the samples
        for (UInt32 frame = 0; frame < (duration_secs * sample_rate); frame++)
        {
            Float32 vol = MAX_VOLUME * sqrt( 1.0 - (pow(frame - ((duration_secs * sample_rate) / 2), 2)
                                                    / pow(((duration_secs * sample_rate) / 2), 2)));
            
            buffer[idx++] = vol * sin(theta);
            
            theta += theta_increment;
            if (theta > 2.0 * M_PI)
            {
                theta -= 2.0 * M_PI;
            }
        }

    }
    
    d = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
    
    
    addWAVHeader();
}



#pragma mark - AVAudioPlayerDelegate <NSObject>

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    
}

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    
}

#pragma mark - 数字转频率
void freq_init() {
	
	static int flag = 0;
	
	if (flag) {
		
		return;
	}
	
	int i, len;
	
	for (i=0, len = strlen(BB_CHARACTERS); i<len; ++i) {
		
		unsigned int freq = (unsigned int)floor(BB_BASEFREQUENCY * pow(BB_SEMITONE, i));
		frequencies[i] = freq;
        
	}
    
    flag = 1;
}

int num_to_freq(int n, unsigned int *f) {
    
    freq_init();
	
	if (f != NULL && n>=0 && n<32) {
		
		*f =  (unsigned int)floor(frequencies[n]);
		
		return 0;
	}
	
	return -1;
}

#pragma mark - 

//wav文件格式详见：http://www-mmsp.ece.mcgill.ca/Documents../AudioFormats/WAVE/WAVE.html
//wav头的结构如下所示：
typedef   struct   {
    char         fccID[4];//"RIFF"标志
    unsigned   long       dwSize;//文件长度
    char         fccType[4];//"WAVE"标志
}HEADER;

typedef   struct   {
    char         fccID[4];//"fmt"标志
    unsigned   long       dwSize;//Chunk size: 16
    unsigned   short     wFormatTag;// 格式类别
    unsigned   short     wChannels;//声道数
    unsigned   long       dwSamplesPerSec;//采样频率
    unsigned   long       dwAvgBytesPerSec;//位速  sample_rate * 2 * chans//为什么乘2呢？因为此时是16位的PCM数据，一个采样占两个byte。
    unsigned   short     wBlockAlign;//一个采样多声道数据块大小
    unsigned   short     uiBitsPerSample;//一个采样占的bit数
}FMT;

typedef   struct   {
    char         fccID[4]; 	//数据标记符＂data＂
    unsigned   long       dwSize;//语音数据的长度，比文件长度小36
}DATA;

int addWAVHeader()
{
    int channels = 1;
    int m = sizeof(Float32);//Each sample is M bytes long
    int sample_rate = SAMPLE_RATE;
    
    //以下是为了建立.wav头而准备的变量
    HEADER   pcmHEADER;
    FMT   pcmFMT;
    DATA   pcmDATA;
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    strcpy(pcmHEADER.fccID,"RIFF");
    pcmHEADER.dwSize=44+d.length;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    strcpy(pcmHEADER.fccType,"WAVE");
    
    wavData = [NSMutableData dataWithBytes:&pcmHEADER length:sizeof(HEADER)];
    //以上是创建wav头的HEADER;

    //以下是创建wav头的FMT;
    strcpy(pcmFMT.fccID,"fmt ");
    pcmFMT.dwSize=16;
    pcmFMT.wFormatTag=3;
    pcmFMT.wChannels=channels;
    pcmFMT.dwSamplesPerSec=sample_rate;
    pcmFMT.dwAvgBytesPerSec=sample_rate * m * channels;//F * M * Nc
    pcmFMT.wBlockAlign=m * channels;//M * Nc
    pcmFMT.uiBitsPerSample=ceil(8 * m);
    
    //    fwrite(&pcmFMT,sizeof(FMT),1,fpCpy); //将FMT写入.wav文件;
    [wavData appendBytes:&pcmFMT length:sizeof(pcmFMT)];
    //以上是创建wav头的FMT;
    
    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
    strcpy(pcmDATA.fccID,"data");
    pcmDATA.dwSize=d.length; //给pcmDATA.dwsize   0以便于下面给它赋值
    
    [wavData appendBytes:&pcmDATA length:sizeof(DATA)];
    
    [wavData appendData:d];
    
    return 0;
}



@end
