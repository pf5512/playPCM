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
#define BB_SEMITONE 			 1.05946311
#define BB_BASEFREQUENCY		 1760
#define BB_CHARACTERS			 "0123456789abcdefghijklmnopqrstuv"
#define BB_THRESHOLD            16
#define BB_HEADER_0             17
#define BB_HEADER_1             19
#define DURATION				0.0872 // seconds 0.1744//
static float frequencies[32];

static NSData *d;

static NSMutableData *wavData;

//wav头的结构如下所示：
typedef   struct   {
    char         fccID[4];//"RIFF"标志
    unsigned   long       dwSize;//文件长度
    char         fccType[4];//"WAVE"标志
}HEADER;

typedef   struct   {
    char         fccID[4];//"fmt"标志
    unsigned   long       dwSize;// 	过渡字节（不定）????
    unsigned   short     wFormatTag;// 格式类别
    unsigned   short     wChannels;//声道数
    unsigned   long       dwSamplesPerSec;//采样频率
    unsigned   long       dwAvgBytesPerSec;//每秒所需的字节数 (位速)  sample_rate * 2 * chans//为什么乘2呢？因为此时是16位的PCM数据，一个采样占两个byte。
    unsigned   short     wBlockAlign;//每个采样需要的字节数，计算公式：声道数 * 每个采样需要的bit  / 8
    unsigned   short     uiBitsPerSample;//一个采样占的bit数
}FMT;

typedef   struct   {
    char         fccID[4]; 	//数据标记符＂data＂
    unsigned   long       dwSize;//录音数据的长度，不包括头部长度
}DATA;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Moderato" ofType:@"mp3"]];
    
    
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
    makeChirp(self.freqNum, DURATION, SAMPLE_RATE, 16);
    
    NSLog(@"wavData  %d",wavData.length);
    
    //    [wavData writeToFile:@"/Users/hanchao/Desktop/fileaaa.wav" atomically:NO];
    
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


//    for (int i = 0; i < 31; i++) {
//        makeChirp(i, DURATION, SAMPLE_RATE, 16);
//        
//        NSLog(@"wavData  %d",wavData.length);
//        
//        //    [wavData writeToFile:@"/Users/hanchao/Desktop/fileaaa.wav" atomically:NO];
//        
//        NSError *error;
//        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:wavData
//                                                         error:&error];
//        
//        if (error) {
//            NSLog(@"error....%@",[error localizedDescription]);
//        }else{
//            self.audioPlayer.delegate = self;
//            [self.audioPlayer prepareToPlay];
//        }
//        
//        [self.audioPlayer play];
//        
//        [NSThread sleepForTimeInterval:1];
//    }


}

#define MAX_INT         0.05

void makeChirp(int freq, double duration_secs, long sample_rate, int bits_persample) {
//    long len_array = (long)duration_secs * sample_rate; // this is the number of samples to generate
//    
//    short wavesamples[len_array]; // this is our array of samples
//    
//    int i;
//    for (i=0; i < len_array; i++) // some funky initializations...
//        wavesamples[i] = 0;
//    
//    
//    unsigned int freq_s;
//    num_to_freq(freq_end,&freq_s);
//    
//    unsigned int freq_e;
//    num_to_freq(freq_end,&freq_e);
//    
//    double k = (double)(freq_e - freq_s) / len_array;
//    double freq = (double)freq_s; // this is our time-to-time frequency value
//    double omega = (double)(PI / sample_rate);
//    
//    long t;
//    for (t=0; t < len_array; t++) {
//        freq += k; // increase frequency over the time with the omega value
//        double c_sample = sin(omega * freq * t) * MAX_INT;
//        
//        wavesamples[t] = (short)(c_sample * 127.0);
//    }
//    
//    d = [[NSData alloc] initWithBytes: wavesamples length:len_array];

    
    unsigned int freq_s;
    num_to_freq(freq,&freq_s);
    
    // Fixed amplitude is good enough for our purposes
	const double amplitude = MAX_INT;
    
	double theta = 0;
	double theta_increment = 2.0 * M_PI * freq_s / sample_rate;
    
    long len_array = (long)(duration_secs * sample_rate);
	Float32 buffer[len_array];
    
    int i;
    for (i=0; i < len_array; i++)
        buffer[i] = 0;
	
	// Generate the samples
	for (UInt32 frame = 0; frame < len_array; frame++)
	{
		buffer[frame] = sin(theta) * amplitude;
		
		theta += theta_increment;
		if (theta > 2.0 * M_PI)
		{
			theta -= 2.0 * M_PI;
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

///* audioPlayerEndInterruption:withOptions: is called when the audio session interruption has ended and this player had been interrupted while playing. */
///* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
//- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags NS_AVAILABLE_IOS(6_0);
//
//- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0);

/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    
}

#pragma mark -


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
int addWAVHeader()
{
//    char src_file[128] = {0};
//    char dst_file[128] = {0};
    int channels = 2;
    int bits = 16;
    int sample_rate = SAMPLE_RATE;
    
    //以下是为了建立.wav头而准备的变量
    HEADER   pcmHEADER;
    FMT   pcmFMT;
    DATA   pcmDATA;
    
//    unsigned   short   m_pcmData;

    
//    printf("parameter analyse succeess\n");
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    strcpy(pcmHEADER.fccID,"RIFF");
    strcpy(pcmHEADER.fccType,"WAVE");
    pcmHEADER.dwSize=44+d.length;   //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    wavData = [NSMutableData dataWithBytes:&pcmHEADER length:sizeof(HEADER)];
    //以上是创建wav头的HEADER;

    //以下是创建wav头的FMT;
    pcmFMT.dwSamplesPerSec=sample_rate;
    pcmFMT.dwAvgBytesPerSec= sample_rate * 2 * channels ;//采样频率 * 量化位数 * 声道数 / 8 //sample_rate * 2 * channels;//pcmFMT.dwSamplesPerSec*sizeof(m_pcmData);
    pcmFMT.uiBitsPerSample=bits;
    
    strcpy(pcmFMT.fccID,"fmt   ");
    pcmFMT.dwSize=16;
    pcmFMT.wBlockAlign=channels * bits / 8;//：声道数 * 每个采样需要的bit  / 8
    pcmFMT.wChannels=channels;
    pcmFMT.wFormatTag=1;
    //以上是创建wav头的FMT;
    
//    fwrite(&pcmFMT,sizeof(FMT),1,fpCpy); //将FMT写入.wav文件;
    [wavData appendBytes:&pcmFMT length:sizeof(pcmFMT)];
    
    
    //以下是创建wav头的DATA;   但由于DATA.dwsize未知所以不能写入.wav文件
    strcpy(pcmDATA.fccID,"data");
    
    pcmDATA.dwSize=d.length; //给pcmDATA.dwsize   0以便于下面给它赋值
    
//    fseek(fpCpy,sizeof(DATA),1); //跳过DATA的长度，以便以后再写入wav头的DATA;
    [wavData appendBytes:&pcmDATA length:sizeof(DATA)];
    
    NSLog(@"=======%d",wavData.length);
    
    [wavData appendData:d];
    
    
    return 0;
}



@end
