module app;
import imps;

public int WindowWidth = 800;
public int WindowHeight = 600;
public int WinFlags = sfTitlebar|sfClose;
public string WindowTitle = "Mitosis - Cellionaires ; FPS = %5.2f";
public sfRenderWindow* rwin;
public StanGry gstate,nstate;
public immutable(ConfBundle) cfg;

static this()
{
	cfg = immutable ConfBundle("config.cfg");
}

private void PrintDevs()
{
	int a, count=0;
	BASS_DEVICEINFO info;
	writeln("--- Urzadzenia audio {");
	for(a=0;BASS_GetDeviceInfo(a,&info);a++)
	{
		if(info.flags & BASS_DEVICE_ENABLED)
		{
			writefln("Device %d: %s",a,info.name[0..strlen(info.name)]);
			count++;
		}
	}
	writeln("--- }");
}

void main()
{
	DerelictGL3.load();
	DerelictSFML2System.load();
	DerelictSFML2Window.load();
	DerelictSFML2Graphics.load();
	DerelictBASS.load();
	PrintDevs();

	WindowWidth = cfg.intValue("video","WinWidth");
	WindowHeight = cfg.intValue("video","WinHeight");
	if(cfg.intValue("video","WinResize")>0)WinFlags |= sfResize;

	if(!BASS_Init(cfg.intValue("audio","Device"),48000,0,null,null))throw new Error(text(BASS_ErrorGetCode()));
	scope(exit)BASS_Free();
	BASS_SetVolume(1.0f);
	BASS_Start();
	sfVideoMode vm = sfVideoMode_getDesktopMode();
	vm.width=WindowWidth;
	vm.height=WindowHeight;
	vm.bitsPerPixel = 32;
	sfContextSettings *cs = new sfContextSettings();
	cs.depthBits=8;
	cs.majorVersion=1;
	cs.minorVersion=2;
	rendMode = new sfRenderStates();
	rendMode.blendMode = sfBlendAdd;
	rwin = sfRenderWindow_create(vm,toStringz(format(WindowTitle,120.0f)),WinFlags,cs);
	sfRenderWindow_setFramerateLimit(rwin,120);
	sfRenderWindow_setVerticalSyncEnabled(rwin,sfTrue);
	gstate = new StanMenu();
	sfClock* fclock,tclock;
	fclock = sfClock_create();
	tclock = sfClock_create();
	double dt,fps,afps=0;
	nstate = gstate;
	while((gstate !is null) && (sfRenderWindow_isOpen(rwin)))
	{
		dt = sfTime_asSeconds(sfClock_restart(fclock));
		fps = 1/dt;
		afps = (fps*5+afps)/6.0;
		if(sfTime_asSeconds(sfClock_getElapsedTime(tclock))>=1.0)
		{
			sfRenderWindow_setTitle(rwin,toStringz(format(WindowTitle,afps)));
			sfClock_restart(tclock);
		}
		nstate = gstate.update(dt,rwin);
		if(nstate != gstate)
		{
			gstate.free();
			gstate = nstate;
			GC.collect();
			continue;
		}
		sfEvent* ev = new sfEvent();
		while(sfRenderWindow_pollEvent(rwin,ev))
		{
			switch(ev.type)
			{
				case sfEvtClosed:
					sfRenderWindow_close(rwin);break;
				default:break;
			}
			gstate.onevent(rwin,ev);
		}
		auto mpos = sfMouse_getPositionRenderWindow(rwin);
		mouseCoord.x = mpos.x;
		mouseCoord.y = mpos.y;
		sfRenderWindow_clear(rwin,sfMagenta);
		gstate.render(rwin);
		sfRenderWindow_display(rwin);
	}
	sfRenderWindow_destroy(rwin);
	return;
}
