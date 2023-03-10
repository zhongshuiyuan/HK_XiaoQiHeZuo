<%@ WebHandler Language="C#" Class="Upload" %>
using System;
using System.Collections;
using System.Globalization;
using System.IO;
using System.Web;
using LitJson;

public class Upload : IHttpHandler
{
    private HttpContext _context;

    public void ProcessRequest(HttpContext context)
    {
        var aspxUrl = context.Request.Path.Substring(0, context.Request.Path.LastIndexOf("/", StringComparison.Ordinal) + 1);
        //string RunDirectory = System.AppDomain.CurrentDomain.SetupInformation.ApplicationBase;
        //文件保存目录路径
        var savePath = "../../../UploadFiles/";

        //文件保存目录URL/
        var saveUrl = aspxUrl + "../../../UploadFiles/";

        //定义允许上传的文件扩展名
        var extTable = new Hashtable();
        extTable.Add("image", "gif,jpg,jpeg,png,bmp");
        extTable.Add("flash", "swf,flv");
        extTable.Add("media", "swf,flv,mp3,wav,wma,wmv,mid,avi,mpg,asf,rm,rmvb");
        extTable.Add("file", "doc,docx,xls,xlsx,ppt,htm,html,txt,zip,rar,gz,bz2,pdf");

        //最大文件大小
        var maxSize = 51814400;
        //int maxSize = 999999999;
        this._context = context;

        var imgFile = context.Request.Files["imgFile"];
        if (imgFile == null) ShowError("请选择文件。");

        var dirPath = context.Server.MapPath(savePath);
        if (!Directory.Exists(dirPath)) ShowError("上传目录不存在。");

        var dirName = context.Request.QueryString["dir"];
        if (string.IsNullOrEmpty(dirName)) dirName = "image";
        if (!extTable.ContainsKey(dirName)) ShowError("目录名不正确。");

        var fileName = imgFile.FileName;
        var fileExt = Path.GetExtension(fileName).ToLower();

        if (imgFile.InputStream.Length > maxSize) ShowError("上传文件大小超过限制。");

        if (string.IsNullOrEmpty(fileExt) ||
            Array.IndexOf(((string)extTable[dirName]).Split(','), fileExt.Substring(1).ToLower()) == -1)
            ShowError("上传文件扩展名是不允许的扩展名。\n只允许" + (string)extTable[dirName] + "格式。");

        //创建文件夹
        dirPath += dirName + "/";
        saveUrl += dirName + "/";
        if (!Directory.Exists(dirPath)) Directory.CreateDirectory(dirPath);
        var ymd = DateTime.Now.ToString("yyyyMMdd", DateTimeFormatInfo.InvariantInfo);
        dirPath += ymd + "/";
        saveUrl += ymd + "/";
        if (!Directory.Exists(dirPath)) Directory.CreateDirectory(dirPath);

        var newFileName = DateTime.Now.ToString("yyyyMMddHHmmss_ffff", DateTimeFormatInfo.InvariantInfo) + fileExt;
        var filePath = dirPath + newFileName;

        imgFile.SaveAs(filePath);

        var fileUrl = saveUrl + newFileName;

        var hash = new Hashtable();
        hash["error"] = 0;
        hash["url"] = fileUrl;
                
        context.Response.AddHeader("Content-Type", "text/html; charset=UTF-8");

        try
        {
            context.Response.Write(JsonMapper.ToJson(hash));
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            throw;
        }
        
        
        context.Response.End();
    }

    public bool IsReusable
          {
             get { return true; }
          }

    private void ShowError(string message)
    {
        var hash = new Hashtable();
        hash["error"] = 1;
        hash["message"] = message;
        _context.Response.AddHeader("Content-Type", "text/html; charset=UTF-8");
        _context.Response.Write(JsonMapper.ToJson(hash));
        _context.Response.End();
    }
}
