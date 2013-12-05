/**
 * Powered by Nerrsoft.com
 *
 * @author Leon Zhuang - leon@nerrsoft.com
 * @link http://nerrsoft.com
 * @version 0.2
 * 
 */


/**
 * property infomation
 *
 */

#property copyright "Copyright ? 2013 Nerrsoft.com"
#property link      "http://nerrsoft.com"



/**
 * define extern variables
 *
 */

extern bool     EnableTrade     = false;    //-- control master only
extern string   BASESETTING     = "---Base Setting---";
extern string   RunningMode     = "slave";  //-- option: [master] or [slave] or [test]
extern double   BaseLots        = 0.1;
extern double   TholdPips       = 8.0;
extern double   StopLossPips    = 50.0;
extern double   TakeProfitPips  = 3.0;
extern int      MagicNumber     = 5257;     //-- it is avliable only master mode
extern bool     MoneyManagment  = false;

extern string   DBSETTING       = "---PostgreSQL Database Settings---";
extern string   dbhost          = "192.168.11.6";
extern string   dbport          = "5432";
extern string   dbuser          = "postgres";
extern string   dbpass          = "911911";
extern string   dbname          = "nst";



/**
 * include library
 *
 */
#include <nst_lib_all.mqh>
#include <postgremql4.mqh>



/**
 * Global variables
 *
 */
int     AccountId, AccountNum, AccountLev, SymbolId, PriceId;
string  SymbolName, SymExt, BrokerName;



/**
 * System Funcs
 *
 */

//-- init
int init()
{
    //-- connect to pgsql
    string res = pmql_connect(dbhost, dbport, dbuser, dbpass, dbname);
    if((res != "ok") && (res != "already connected"))
    {
        pubLog2Db("DB not connected!", "PGSQL-ERR");
        return (-1);
    }

    //-- get account id by account number 
    AccountNum = AccountNumber();
    AccountLev = AccountLeverage();
    BrokerName = AccountCompany();
    SymbolName = StringSubstr(Symbol(), 0, 6);
    if(StringLen(Symbol()) > 6)
        SymExt = StringSubstr(Symbol(),6);
    //-- get account id from db
    AccountId  = getAccountId(AccountNum, BrokerName, AccountLev); //-- todo -> get AccountId
    //-- get symbolid and priceid
    SymbolId   = getSymbolId(SymbolName);
    PriceId    = getPriceId(AccountId, SymbolId);

    //-- init price record
    //initPriceTable(); //-- todo -> ...
}

//-- deinit
int deinit()
{
    pmql_disconnect();
    return(0);
}

//-- start
int start()
{
    if(RunningMode == "master")
        master();
    else if(RunningMode == "slave")
        slave();
    else if(RunningMode == "test")
        test();
    else
        pubLog2Db("Please check the mode setting (master or slave or test).");
}


/**
 * Mode Funcs
 *
 */

//-- master mode
void master()
{
    //-- check command
    masterHandleCommand();

    //-- get local price bid & ask
    masterDiffPrice(SymbolName);

    //-- load avilable slave price and find chance


    //-- todo ->

}

//-- slave mode
void slave()
{
    //-- get orders array
    string CommandArr[500, 8];
    pubGetCommandArray(SymbolId, RunningMode, AccountId, MagicNumber, CommandArr);

    //-- check commands
    slaveCheckCommand(CommandArr);

    //-- get orders array
    string OrderArr[500, 10];
    pubGetOrderArray(SymbolName + SymExt, OrderArr, MagicNumber);

    //-- check order
    slaveCheckOrder();

    //-- update price to db
    slaveUpdatePrice(PriceId);

    //-- update order profit + swap + commission to db
    slaveUpdateOrderProfit(OrderArr);
}

//-- test mode
void test()
{
    //-- todo -> test mode
}



/**
 * Init Funcs
 * use to get init data and init settings
 */

//--
int getAccountId(int _an, string _bn, int _lev)
{
    int _id = 0;
    string squery = "SELECT id FROM nst_sys_account WHERE accountnumber='" + _an + "' AND broker='" + _bn + "'";
    string res = pmql_exec(squery);
    if(res == "")
    {
        string iquery = "INSERT INTO nst_sys_account (strategyid, accountnumber, broker, leverage) VALUES (3, " + _an + ", '" + _bn + "', " + _lev + ")";
        res = pmql_exec(iquery);
        if(res == "")
        {
            res = pmql_exec(squery);
            _id = StrToInteger(StringSubstr(res, 3, -1));
        }
    }
    else
        _id = StrToInteger(StringSubstr(res, 3, -1));

    //-- return 
    if(_id > 0)
        return(_id);
    else
        return(0);
}

//-- 
int getPriceId(int _aid, int _sid)
{
    int _id = 0;
    string squery = "SELECT id FROM nst_mbt_price WHERE accountid='" + _aid + "' AND symbolid='" + _sid + "'";
    string res = pmql_exec(squery);
    if(res == "")
    {
        string iquery = "INSERT INTO nst_mbt_price (accountid, symbolid) VALUES (" + _aid + ", " + _sid + ")";
        res = pmql_exec(iquery);
        if(res == "")
        {
            res = pmql_exec(squery);
            _id = StrToInteger(StringSubstr(res, 3, -1));
        }
    }
    else
        _id = StrToInteger(StringSubstr(res, 3, -1));

    //-- return 
    if(_id > 0)
        return(_id);
    else
        return(0);
}

//--
int getSymbolId(string _sn)
{
    int _id = 0;
    string squery = "SELECT id FROM nst_mbt_symbol WHERE symbolname='" + _sn +"'";
    string res = pmql_exec(squery);
    if(res == "")
    {
        string iquery = "INSERT INTO nst_mbt_symbol (symbolname) VALUES ('" + _sn + "')";
        res = pmql_exec(iquery);
        if(res == "")
        {
            res = pmql_exec(squery);
            _id = StrToInteger(StringSubstr(res, 3, -1));
        }
    }
    else
        _id = StrToInteger(StringSubstr(res, 3, -1));

    //-- return 
    if(_id > 0)
        return(_id);
    else
        return(0);
}


/**
 * Slave Funcs
 * the func who use for slave mode only
 */

void masterHandleCommand()
{

}

void masterDiffPrice()
{

}

int masterOrderTotal()
{

}


/**
 * Slave Funcs
 * the func who use for slave mode only
 */

//-- update price to database
//-- pid (price id) = symbol record id in price table
void slaveUpdatePrice(int _pid)
{
    RefreshRates();

    string query = "";
    query = "UPDATE nst_mbt_price SET";
    query = query + " bidprice=" + Bid + ",";
    query = query + " askprice=" + Ask + ",";
    query = query + " loctime='" + libDatetimeTm2str(TimeLocal()) + "',";
    query = query + " sertime='" + libDatetimeTm2str(TimeCurrent()) + "'";
    query = query + " WHERE id=" + _pid;

    string res = pmql_exec(query);

    if(StringLen(res)>0)
        pubLog2Db("Update price to db error: SQL return [" + res + "]", "NST-MBT-LOG");
}

//-- slave func - update slave order profit info to `nst_mbt_slave_profit` table
int slaveUpdateOrderProfit(string _arr[][])
{
    int size = ArrayRange(_arr, 1);

    if(size <= 0) return(0);

    string query = "";
    string res   = "";
    for(int i = 0; i < size; i++)
    {
        query = "UPDATE nst_mbt_slave_profit SET slaveorderprofit=" + _arr[i][9] + ",slaveswap=" + _arr[i][9] + ", slavecommission=" + _arr[i][4] + " logtime='" + libDatetimeTm2str(TimeLocal()) + "' WHERE commandid=" + _cid;
        string res = pmql_exec(query);

        if(StringLen(res)>0)
            pubLog2Db("Update slave profit to db error: SQL return [" + res + "]", "NST-MBT-LOG");
    }

    return(1);
}

//--
int slaveCheckCommand(string _arr)
{
    int size = ArrayRange(_arr, 1);

    if(size <= 0) return(0);

    int _ticket = 0;
    double _totalprofit = 0;

    for(int i = 0; i < size; i++)
    {
        //-- open order command 
        if(_arr[i][4] == "0")
        {
            _ticket = 0;
            _ticket = pubOrderOpen(); //-- todo ->
            if(_ticket > 0 && OrderSelect(_ticket, SELECT_BY_TICKET) == true)
            {
                slaveUpdateCommandInfo(_arr[i][0], _ticket, OrderOpenPrice(), 2);
                slaveInsertProfit(_arr[i][0]);
            }
            else
            {
                pubSetCommandStatus(_arr[i][0], 1);
                pubLog2Db("Slave open order fail, command[" + _arr[i][0] + "]", "NST-MBT-LOG");
            }
        }
        else if(_arr[i][4] == "3")
        {
            _ticket = 0;
            _ticket = pubOrderOpen(); //-- todo ->
            if(_ticket > 0 && OrderSelect(_ticket, SELECT_BY_TICKET) == true)
            {
                slaveUpdateCommandInfo(_arr[i][0], _ticket, OrderOpenPrice(), 5);
                slaveInsertProfit(_arr[i][0]);
            }
            else
            {
                pubSetCommandStatus(_arr[i][0], 4);
                pubLog2Db("Slave open limit order fail, command[" + _arr[i][0] + "]", "NST-MBT-LOG");
            }
        }
        else if(_arr[i][4] == "5") //-- todo -> need to test
        {
            if()
            {
                pubSetCommandStatus(_arr[i][0], 4);
            }
        }
        else if(_arr[i][4] == "8")
        {
            _ticket = StrToInteger(_arr[i][10]);
            if(OrderSelect(_ticket, SELECT_BY_TICKET) == true)
            {
                //-- delete pending order
                if(OrderTpye() > 1)
                    OrderDelete(_ticket);
                else
                {
                    _totalprofit = 0;
                    _totalprofit = slaveGetMasterOrderTotalProfit(_arr[i][0]) + OrderProfit() + OrderSwap() + OrderCommission();

                    if(_totalprofit > 0)
                    {
                        if(pubOrderClose(_ticket) == true)
                            pubSetCommandStatus(_arr[i][0], 9);
                        else
                            pubLog2Db("Close Slave order[" + _ticket + "] fail", "NST-MBT-LOG");
                    }
                    else
                    {
                        if(pubSetOrderSTTP(_ticket, TakeProfitPips, StopLossPips) == true)
                            pubSetCommandStatus(_arr[i][0], 9);
                        else
                            pubLog2Db("Close Slave order[" + _ticket + "] fail", "NST-MBT-LOG");
                    }
                }
            }
            else
                pubSetCommandStatus(_arr[i][0], 9);
        }
    }

    return(1);
}

//--
void slaveCheckOrder()
{
    int size = ArrayRange(_arr, 1);
}

bool slaveInsertProfit(string _cid)
{
    string _query = "INSERT INTO nst_mbt_slave_profit (commandid) VALUES (" + _cid + ")";
    string _res   = pmql_exec(_query);
    if(StringLen(_res)>0)
    {
        pubLog2Db("Insert slave profit data fail [" + _res + "] commandid[" + _cid + "]", "NST-MBT-LOG");
        return(false);
    }
    else
        return(true);
}

//-- command id & order ticket & open price & command status id
bool slaveUpdateCommandInfo(string _cid, int _ticket, double _op, int _sid)
{
    string _query = "UPDATE nst_mbt_command SET commandstatus=" + _sid + ", slaveorderid=" + _ticket + ", slaveopenprice=" + _op + ",WHERE id=" + _cid;
    string _res   = pmql_exec(_query);
    if(StringLen(_res)>0)
    {
        pubLog2Db("Update command status fail [" + _res + "]", "NST-MBT-LOG");
        return(false);
    }
    else
        return(true);
}

/**
 * slaveGetMasterOrderTotalProfit()
 * called by slave() and use to get closed master order total profit (profit + commission + swap) from database
 * if func return -99999 then query fail
 *
 * @param int _cid - command id
 */
double slaveGetMasterOrderTotalProfit(string _cid)
{
    double _profit = -99999;
    string _query = "SELECT mastercloseprofit,mastercloseswap,masterclosecommission from nst_mbt_master_closed_profit WHERE commandid=" + _cid;
    string _res   = pmql_exec(_query);

    if(StringLen(_res) > 0)
    {
        string _data[,3];
        libPgsqlFetchArr(_res, _data);

        _profit = StrToDouble(_data[0][0]) + StrToDouble(_data[0][1])) + StrToDouble(_data[0][2]);
    }

    return(_profit);
}




/**
 * Public Funcs
 * public funcs in this EA
 */

void pubLog2Db(string _logtext, string _type="Information")
{
    libDebugOutputLog(_logtext, _type);
    string query = "INSERT INTO nst_mbt_tradinglog (logdatetime, logtype, logcontent) VALUES ('" + libDatetimeTm2str(TimeLocal()) + "', '" + _type + "', '" + _logtext + "')";
    string res = pmql_exec(query);
    if(StringLen(res)>0)
        libDebugSendAlert("Can not insert log to database.", "NST-MBT-LOG");
}

int pubOrderOpen()
{
    //-- todo -> slave order use commandid as comment
}

bool pubOrderCloseByTicket(int _ticket)
{
    bool _status = false;
    if(OrderSelect(_ticket, SELECT_BY_TICKET))
    {
      if (OrderType() == OP_BUY)  _status = OrderClose(_ticket, OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3);
      if (OrderType() == OP_SELL) _status = OrderClose(_ticket, OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 3);
    }
    else
        pubLog2Db("Close order by ticket fail can not select the ticket[" + _ticket + "] " + GetLastError(), "NST-MBT-LOG");

    return(_status);
}

bool pubSetOrderSTTP()
{
    //--
}

//--
int pubGetOrderArray(string _sym, string _arr[][], int _mn = 0) //-- magic number = 0 mean all order
{
    int symordernum = 0;
    //ArrayResize(_arr, ordernum);

    int ordernum = OrdersTotal();
    for(int i = 0; i < ordernum; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == _mn && OrderSymbol() == _sym)
            {
                _arr[symordernum, 0] = OrderTicket();
                _arr[symordernum, 1] = OrderType();
                _arr[symordernum, 2] = OrderOpenPrice();
                _arr[symordernum, 3] = OrderComment();
                _arr[symordernum, 4] = OrderCommission();
                _arr[symordernum, 5] = OrderLots();
                _arr[symordernum, 6] = OrderSwap();
                _arr[symordernum, 7] = OrderStopLoss();
                _arr[symordernum, 8] = OrderTakeProfit();
                _arr[symordernum, 9] = OrderProfit();

                symordernum++;
            }
        }
    }

    ArrayResize(_arr, symordernum);

    return(symordernum);
}

//-- public func - get command from db return result rows and string array (need define array index)
int pubGetCommandArray(int _symid, string _mode, int _aid, int _mn, string &_arr[][])
{
    //-- make where
    string _where = "";
    if(_mode == "slave")
        _where = " WHERE slaveaid=" + _aid + " AND orderstatus in (0,3,5,8)";
    else if(_mode == "master")
        _where = " WHERE masteraid=" + _aid + " AND orderstatus in (0,1,2,4,5,6)";

    _where = _where + " AND symbolid=" + _symid + " AND ordermagicnum=" + _mn;

    //-- query command
    int _rows = 0;
    string query, res;
    query = "select id, masteraid, slaveaid, createtime, commandstatus, commandtype, symbolid, orderlots, ordercomment, masterorderid, slaveorderid, masteropenprice, slaveopenprice, ordermagicnum from nst_mbt_command" + _where;
    res = pmql_exec(query);

    //-- get array result and result row number
    if(StringLen(res)>0)
    {
        libPgsqlFetchArr(res, _arr);
        _rows = ArraySize(_arr);
    }

    return(_rows);
}

//-- update command status
bool pubSetCommandStatus(string _cid, int _sid) //-- command id & status id
{
    string _query = "UPDATE nst_mbt_command SET commandstatus=" + _sid + " WHERE id=" + _cid;
    string _res   = pmql_exec(_query);
    if(StringLen(_res)>0)
    {
        pubLog2Db("Update command status fail [" + _res + "]", "NST-MBT-LOG");
        return(false);
    }
    else
        return(true);
}