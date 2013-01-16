/*
 
 This code is MIT licensed, see http://www.opensource.org/licenses/mit-license.php
 (C) 2013 Nightspade
 
 */

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"
#include "AdColonyPublic.h"

// some Lua helper functions
#ifndef abs_index
#define abs_index(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)
#endif

static void luaL_newweaktable(lua_State *L, const char *mode)
{
	lua_newtable(L);			// create table for instance list
	lua_pushstring(L, mode);
	lua_setfield(L, -2, "__mode");	  // set as weak-value table
	lua_pushvalue(L, -1);             // duplicate table
	lua_setmetatable(L, -2);          // set itself as metatable
}

static void luaL_rawgetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_rawget(L, idx);
}

static void luaL_rawsetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_insert(L, -2);
	lua_rawset(L, idx);
}

enum
{
	GADCOLONY_VIDEO_INITIALIZED_EVENT,
	GADCOLONY_VIDEO_READY_EVENT,
	GADCOLONY_VIDEO_NOT_READY_EVENT,
	GADCOLONY_VIDEO_STARTED_EVENT,
	GADCOLONY_VIDEO_FINISHED_EVENT,
};

static const char *VIDEO_INITIALIZED = "videoInitialized";
static const char *VIDEO_READY = "videoReady";
static const char *VIDEO_NOT_READY = "videoNotReady";
static const char *VIDEO_STARTED = "videoStarted";
static const char *VIDEO_FINISHED = "videoFinished";

static char keyWeak = ' ';

class CAdColony;

@interface CAdColonyDelegate : NSObject<AdColonyDelegate, AdColonyTakeoverAdDelegate>
{
}

- (id) initWithInstance:(CAdColony*)ads;

@property (nonatomic, assign) CAdColony *ads;
@property (nonatomic, copy) NSString *adColonyID;
@property (nonatomic, copy) NSString *adZone;

@end

class CAdColony : public GEventDispatcherProxy
{
public:
	CAdColony(lua_State *L) : L(L), enabled_(true), configured_(false)
	{
        delegate_ = [[CAdColonyDelegate alloc] initWithInstance:this];
        [AdColony initAdColonyWithDelegate:delegate_];
    }
    
	~CAdColony()
	{
        delegate_.ads = nil;
        [delegate_ release];
	}
    
	void configure(const char* appId, const char* zoneId)
	{
		delegate_.adColonyID = [NSString stringWithUTF8String:appId];
        delegate_.adZone = [NSString stringWithUTF8String:zoneId];
        configured_ = true;
	}
	
	bool isConfigured()
	{
		return configured_;
	}
	
	void enable(bool enabled)
	{
        enabled_ = enabled;
	}
	
	void showVideo(const char* zoneId)
	{
        if (enabled_){
            dispatchEvent(GADCOLONY_VIDEO_INITIALIZED_EVENT, NULL);
            
            if (zoneId) {
                [AdColony playVideoAdForZone:[NSString stringWithUTF8String:zoneId] withDelegate:delegate_];
            } else {
                [AdColony playVideoAdForSlot:1 withDelegate:delegate_];
            }
        }
	}
	
	void offerV4VC(const char* zoneId, bool postPopup)
	{
        if (enabled_){
            dispatchEvent(GADCOLONY_VIDEO_INITIALIZED_EVENT, NULL);
            if (zoneId) {
                [AdColony playVideoAdForZone:[NSString stringWithUTF8String:zoneId] withDelegate:delegate_ withV4VCPrePopup:YES andV4VCPostPopup:postPopup];
            } else {
                [AdColony playVideoAdForSlot:1 withDelegate:delegate_ withV4VCPrePopup:YES andV4VCPostPopup:postPopup];
            }
        }
	}
	
	void showV4VC(const char* zoneId, bool postPopup)
	{
        if (enabled_){
            dispatchEvent(GADCOLONY_VIDEO_INITIALIZED_EVENT, NULL);
            if (zoneId) {
                [AdColony playVideoAdForZone:[NSString stringWithUTF8String:zoneId] withDelegate:delegate_ withV4VCPrePopup:NO andV4VCPostPopup:postPopup];
            } else {
                [AdColony playVideoAdForSlot:1 withDelegate:delegate_ withV4VCPrePopup:YES andV4VCPostPopup:postPopup];
            }
        }
	}
    
	void dispatchEvent(int type, void *event)
	{
		luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
		luaL_rawgetptr(L, -1, this);
        
		if (lua_isnil(L, -1))
		{
			lua_pop(L, 2);
			return;
		}
        
		lua_getfield(L, -1, "dispatchEvent");
        
		lua_pushvalue(L, -2);
        
		lua_getglobal(L, "Event");
		lua_getfield(L, -1, "new");
		lua_remove(L, -2);
        
		switch (type)
		{
            case GADCOLONY_VIDEO_INITIALIZED_EVENT:
                lua_pushstring(L, VIDEO_INITIALIZED);
                break;
            case GADCOLONY_VIDEO_READY_EVENT:
                lua_pushstring(L, VIDEO_READY);
                break;
            case GADCOLONY_VIDEO_NOT_READY_EVENT:
                lua_pushstring(L, VIDEO_NOT_READY);
                break;
            case GADCOLONY_VIDEO_STARTED_EVENT:
                lua_pushstring(L, VIDEO_STARTED);
                break;
            case GADCOLONY_VIDEO_FINISHED_EVENT:
                lua_pushstring(L, VIDEO_FINISHED);
                break;
		}
        
		lua_call(L, 1, 1);
        
		lua_call(L, 2, 0);
        
		lua_pop(L, 2);
	}
    
private:
	lua_State *L;
    
    CAdColonyDelegate *delegate_;
    bool enabled_;
    bool configured_;
};

@implementation CAdColonyDelegate

@synthesize ads = ads_;
@synthesize adColonyID = adColonyID_;
@synthesize adZone = adZone_;

-(id)initWithInstance:(CAdColony*)ads
{
	if (self = [super init])
	{
        ads_ = ads;
	}
	
	return self;
}

-(NSString*)adColonyApplicationID{
    return adColonyID_;
}

-(NSDictionary*)adColonyAdZoneNumberAssociation{
    return [NSDictionary dictionaryWithObjectsAndKeys:
           adZone_, [NSNumber numberWithInt:1], //video zone 1
            nil];
}

- (void)dealloc
{
    [super dealloc];
}

- ( void ) adColonyNoVideoFillInZone:( NSString * )zone
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_NOT_READY_EVENT, NULL);
}

- ( void ) adColonyVideoAdsReadyInZone:( NSString * )zone
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_READY_EVENT, NULL);
}

- ( void ) adColonyVideoAdsNotReadyInZone:( NSString * )zone
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_NOT_READY_EVENT, NULL);
}

- ( void ) adColonyTakeoverBeganForZone:( NSString * )zone
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_STARTED_EVENT, NULL);
}

- ( void ) adColonyTakeoverEndedForZone:( NSString * )zone withVC:( BOOL )withVirtualCurrencyAward
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_FINISHED_EVENT, NULL);
}

- ( void ) adColonyVideoAdNotServedForZone:( NSString * )zone
{
    if (ads_)
        ads_->dispatchEvent(GADCOLONY_VIDEO_NOT_READY_EVENT, NULL);
}

@end

static int destruct(lua_State* L)
{
	void *ptr =*(void**)lua_touserdata(L, 1);
	GReferenced* object = static_cast<GReferenced*>(ptr);
	CAdColony *adcolony = static_cast<CAdColony*>(object->proxy());
    
	adcolony->unref();
    
	return 0;
}

static CAdColony *getInstance(lua_State *L, int index)
{
	GReferenced *object = static_cast<GReferenced*>(g_getInstance(L, "AdColony", index));
	CAdColony *adcolony = static_cast<CAdColony*>(object->proxy());
    
	return adcolony;
}

static int configure(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	const char *appId = lua_tostring(L, 2);
	const char *zoneId = lua_tostring(L, 3);
	
	adcolony->configure(appId, zoneId);
	
	return 0;
}

static int isConfigured(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	lua_pushboolean(L, adcolony->isConfigured());
	
	return 0;
}

static int enable(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	bool enabled = lua_toboolean(L, 2);
	
	adcolony->enable(enabled);
	
	return 0;
}

static int showVideo(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	const char *zoneId = lua_tostring(L, 2);
	
	adcolony->showVideo(zoneId);
	
	return 0;
}

static int offerV4VC(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	const char *zoneId = lua_tostring(L, 2);
	bool postPopup = lua_toboolean(L, 3);
	
	adcolony->offerV4VC(zoneId, postPopup);
	
	return 0;
}

static int showV4VC(lua_State *L)
{
	CAdColony *adcolony = getInstance(L, 1);
	
	const char *zoneId = lua_tostring(L, 2);
	bool postPopup = lua_toboolean(L, 3);
	
	adcolony->showV4VC(zoneId, postPopup);
	
	return 0;
}


static int loader(lua_State *L)
{
	const luaL_Reg functionList[] = {
		{"configure", configure},
		{"isConfigured", isConfigured},
		{"enable", enable},
		{"showVideo", showVideo},
		{"offerV4VC", offerV4VC},
		{"showV4VC", showV4VC},
		{NULL, NULL}
	};
    
    g_createClass(L, "AdColony", "EventDispatcher", NULL, destruct, functionList);
    
    // create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of keyWeak
	luaL_newweaktable(L, "v");
	luaL_rawsetptr(L, LUA_REGISTRYINDEX, &keyWeak);
    
    lua_getglobal(L, "Event");
	lua_pushstring(L, VIDEO_INITIALIZED);
	lua_setfield(L, -2, "VIDEO_INITIALIZED");
	lua_pushstring(L, VIDEO_READY);
	lua_setfield(L, -2, "VIDEO_READY");
	lua_pushstring(L, VIDEO_NOT_READY);
	lua_setfield(L, -2, "VIDEO_NOT_READY");
	lua_pushstring(L, VIDEO_STARTED);
	lua_setfield(L, -2, "VIDEO_STARTED");
	lua_pushstring(L, VIDEO_FINISHED);
	lua_setfield(L, -2, "VIDEO_FINISHED");
	lua_pop(L, 1);
    
	CAdColony *instance = new CAdColony(L);
	g_pushInstance(L, "AdColony", instance->object());
    
	luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
	lua_pushvalue(L, -2);
	luaL_rawsetptr(L, -2, instance);
	lua_pop(L, 1);
    
	lua_pushvalue(L, -1);
	lua_setglobal(L, "adcolony");
    
    return 1;
}

static void g_initializePlugin(lua_State *L)
{
    lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
    
	lua_pushcfunction(L, loader);
	lua_setfield(L, -2, "adcolony");
    
	lua_pop(L, 2);
}

static void g_deinitializePlugin(lua_State *L)
{
    
}

REGISTER_PLUGIN("AdColony", "2012.12")
