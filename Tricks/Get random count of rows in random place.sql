set statistics io, time on

USE [CMS]
DECLARE @ArticleID int =2882702, @CategoryID int = 1137


;WITH
cte AS(
SELECT 
	ROW_NUMBER() OVER (ORDER BY a.[artActiveDate], a.[artTitle] DESC) RN,
	a.[artArticleID], 
	a.[artTitle],
  SUM(CASE WHEN artArticleID = @ArticleID THEN 1 ELSE 0 END) OVER (ORDER BY a.[artActiveDate], a.[artTitle] DESC ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) ch
FROM [CMS].[dbo].[ArticleCategories] ac WITH (NOLOCK)
   JOIN [CMS].[dbo].[Articles] a WITH (NOLOCK) ON ac.[acArticleID] = a.[artArticleID] 
WHERE 
  ac.[acCategoryID] = @CategoryID
  AND a.[artActive] = 1
)
SELECT 
	cte.RN,
	cte.artArticleID,
	cte.artTitle
FROM cte
WHERE ch =1
------------------------------

--CASE WHEN artArticleID = @ArticleID -  здесь определяется точка входа в диапазон 

--ROWS BETWEEN 1 PRECEDING  - определить сколько строк получить до точки входа 
--AND 1 FOLLOWING - определить сколько строк получить после точки входа
-- таким образом если определить равное кол-во строк в PRECEDING  и FOLLOWING, --то получим равноудаленный диапазон строк от точки входа

/* 
Задача которая решалась данным методом
Есть некий массив который упорядочивается по ROW_NUMBER() OVER (ORDER BY a.[artActiveDate], a.[artTitle] DESC) 
Внутри этого массива есть произвольная точка входа artArticleID = @ArticleID 
Нужно взять строку для точки входа и два крайних значения для нее относительно порядка ROW_NUMBER()
*/